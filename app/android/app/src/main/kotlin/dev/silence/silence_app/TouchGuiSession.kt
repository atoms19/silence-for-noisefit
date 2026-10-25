package dev.silence.silence_app

import android.annotation.SuppressLint
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.os.Build
import android.os.Handler
import java.security.MessageDigest
import java.util.UUID

/**
 * TouchGUI companion handshake for ColorFit Pulse 2: enable notifications, negotiate MTU,
 * query device info, then send the bind command. Sequence and byte layouts come from static
 * analysis of NoiseFit 5.4.6 (docs/silence-os/07-touchgui-bind.md); nothing else is written.
 * Every packet in both directions is emitted as a "protocol" event.
 */
@SuppressLint("MissingPermission")
class TouchGuiSession(
    private val gatt: BluetoothGatt,
    private val handler: Handler,
    private val emit: (Map<String, Any?>) -> Unit,
) {
    private enum class Stage { IDLE, NOTIFY, MTU, DEVICE_INFO, BIND, DONE }

    private var stage = Stage.IDLE
    private var commandChar: BluetoothGattCharacteristic? = null
    private val pendingDescriptors = ArrayDeque<BluetoothGattDescriptor>()
    private var timeout: Runnable? = null
    private var bindSent = false
    private var bound = false
    private var deviceId = 0
    private var protocolVersion = 0
    private var mtu = 23
    private var fileChar: BluetoothGattCharacteristic? = null
    private var upload: Upload? = null
    private val writeQueue = ArrayDeque<Pair<BluetoothGattCharacteristic, ByteArray>>()
    private var writing = false
    private var writeRetries = 0

    fun start() {
        if (stage != Stage.IDLE) return
        val services = gatt.services.filter { it.uuid in TOUCHGUI_SERVICES }
        val primary = services.firstOrNull { it.uuid == SERVICE_27F0 }
            ?: services.firstOrNull { it.uuid == SERVICE_0AF0 }
        commandChar = primary?.getCharacteristic(if (primary.uuid == SERVICE_27F0) CHAR_27F1 else CHAR_0AF1)
        fileChar = primary?.getCharacteristic(if (primary.uuid == SERVICE_27F0) CHAR_27F6 else CHAR_0AF6)
        if (primary == null || commandChar == null) {
            fail("This device does not expose the TouchGUI service. It may not be a Pulse 2.")
            return
        }
        for (service in services) {
            for (characteristic in service.characteristics) {
                if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY == 0) continue
                val cccd = characteristic.getDescriptor(CCCD) ?: continue
                gatt.setCharacteristicNotification(characteristic, true)
                pendingDescriptors.addLast(cccd)
            }
        }
        stage = Stage.NOTIFY
        progress("Enabling notifications (${pendingDescriptors.size})")
        nextDescriptor()
    }

    fun cancel() {
        clearTimeout()
        stage = Stage.IDLE
        upload = null
        bound = false
        writeQueue.clear()
        writing = false
        pendingDescriptors.clear()
    }

    fun onDescriptorWrite(status: Int) {
        if (stage != Stage.NOTIFY) return
        if (status != BluetoothGatt.GATT_SUCCESS) {
            fail("Enabling notifications failed (GATT status $status).")
            return
        }
        nextDescriptor()
    }

    fun onMtuChanged(mtu: Int, status: Int) {
        if (status == BluetoothGatt.GATT_SUCCESS && mtu >= 23) this.mtu = mtu
        if (stage != Stage.MTU) return
        log("rx", "mtu", "mtu=$mtu status=$status")
        sendDeviceInfo()
    }

    fun onNotification(characteristic: BluetoothGattCharacteristic, value: ByteArray) {
        if (stage == Stage.IDLE) return
        log("rx", characteristic.uuid.toString(), value.hex())
        if (stage == Stage.DONE) {
            if (value.isNotEmpty() && value[0] == LONG_PREFIX) {
                handleLongPacket(value)
            } else if (value.size >= 2) {
                val active = upload
                when {
                    active != null -> handleUploadReply(active, value)
                    value[0] == 0x07.toByte() -> handleWatchEvent(value)
                    else -> handleShortReply(value)
                }
            }
            return
        }
        if (value.size < 2) return
        val a = value[0].toInt()
        val b = value[1].toInt()
        when {
            stage == Stage.DEVICE_INFO && a == 0x02 && b == 0x01 -> {
                val fields = parseDeviceInfo(value)
                if (fields.size >= 13) {
                    deviceId = fields[0]
                    protocolVersion = fields[11]
                }
                emit(mapOf("type" to "pair", "stage" to "deviceInfo", "fields" to fields))
                sendBind("Device info received. Sending bind.")
            }
            stage == Stage.BIND && a == 0x04 && b == 0x01 && value.size > 2 -> {
                val state = value[2].toInt()
                clearTimeout()
                stage = Stage.DONE
                bound = state == 0
                emit(mapOf("type" to "pair", "stage" to "bindResult", "state" to state,
                    "success" to (state == 0), "hex" to value.hex()))
            }
        }
    }

    private fun nextDescriptor() {
        val descriptor = pendingDescriptors.removeFirstOrNull()
        if (descriptor == null) {
            stage = Stage.MTU
            progress("Requesting MTU")
            arm(MTU_TIMEOUT_MS) {
                log("rx", "mtu", "no callback; continuing")
                sendDeviceInfo()
            }
            if (!gatt.requestMtu(REQUESTED_MTU)) sendDeviceInfo()
            return
        }
        arm(STEP_TIMEOUT_MS) { fail("Enabling notifications timed out.") }
        val ok = if (Build.VERSION.SDK_INT >= 33) {
            gatt.writeDescriptor(descriptor, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE) == 0
        } else {
            @Suppress("DEPRECATION")
            descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
            @Suppress("DEPRECATION")
            gatt.writeDescriptor(descriptor)
        }
        if (!ok) fail("Android refused to enable notifications.")
    }

    private fun sendDeviceInfo() {
        if (stage == Stage.DEVICE_INFO) return
        stage = Stage.DEVICE_INFO
        progress("Querying device info")
        arm(STEP_TIMEOUT_MS) {
            // The SDK always queries first; if the reply never comes, bind anyway and say so.
            sendBind("No device-info reply. Trying bind anyway.")
        }
        write(byteArrayOf(0x02, 0x01))
    }

    private fun sendBind(message: String) {
        if (bindSent) return
        bindSent = true
        stage = Stage.BIND
        progress(message)
        arm(BIND_TIMEOUT_MS) { fail("The watch did not answer the bind request.") }
        write(byteArrayOf(0x04, 0x01, 0xF3.toByte(), 0x00, 0x00, 0x00))
    }

    private fun write(bytes: ByteArray) {
        val characteristic = commandChar ?: return
        enqueue(characteristic, bytes)
    }

    /** Called from the GATT callback once a queued write has completed. */
    fun onCharacteristicWrite(status: Int) {
        writing = false
        writeRetries = 0
        if (status != BluetoothGatt.GATT_SUCCESS) {
            fail("A write failed (GATT status $status).")
            return
        }
        pumpWrites()
    }

    private fun enqueue(characteristic: BluetoothGattCharacteristic, bytes: ByteArray) {
        writeQueue.addLast(characteristic to bytes)
        pumpWrites()
    }

    private fun pumpWrites() {
        if (writing) return
        val (characteristic, bytes) = writeQueue.firstOrNull() ?: return
        if (!attemptWrite(characteristic, bytes)) {
            if (++writeRetries > MAX_WRITE_RETRIES) {
                fail("Android refused the write.")
            } else {
                handler.postDelayed({ pumpWrites() }, WRITE_RETRY_MS)
            }
            return
        }
        writeQueue.removeFirst()
        writing = true
        if (!(upload != null && bytes.size > 3 && bytes[0] == 0xD1.toByte() && bytes[1] == 0x02.toByte())) {
            log("tx", characteristic.uuid.toString(), bytes.hex())
        }
    }

    private fun attemptWrite(characteristic: BluetoothGattCharacteristic, bytes: ByteArray): Boolean =
        if (Build.VERSION.SDK_INT >= 33) {
            gatt.writeCharacteristic(characteristic, bytes, BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE) == 0
        } else {
            @Suppress("DEPRECATION")
            characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
            @Suppress("DEPRECATION")
            characteristic.value = bytes
            @Suppress("DEPRECATION")
            gatt.writeCharacteristic(characteristic)
        }

    /** Mirrors the SDK's little-endian layout after the two command bytes. */
    private fun parseDeviceInfo(value: ByteArray): List<Int> {
        val out = mutableListOf<Int>()
        var i = 2
        fun u8(): Int? = if (i < value.size) (value[i++].toInt() and 0xFF) else null
        fun u16(): Int? {
            if (i + 1 >= value.size) return null
            val v = (value[i].toInt() and 0xFF) or ((value[i + 1].toInt() and 0xFF) shl 8)
            i += 2
            return v
        }
        u16()?.let(out::add)
        repeat(10) { u8()?.let(out::add) }
        u16()?.let(out::add)
        u8()?.let(out::add)
        return out
    }

    // ---- Status queries and time sync (short commands on the command channel) ----

    /** Sends a status query or time sync; replies arrive as "status" events. */
    fun statusCommand(kind: String) {
        if (!bound) {
            emit(mapOf("type" to "status", "kind" to kind, "failed" to "Pair the watch first."))
            return
        }
        when (kind) {
            "battery" -> write(byteArrayOf(0x02, 0x05))
            "version" -> write(byteArrayOf(0x02, 0x11))
            "time" -> write(timeSyncPacket())
            else -> emit(mapOf("type" to "status", "kind" to kind, "failed" to "Unknown query."))
        }
    }

    /** Writes already-built short-command bytes (for example weather) on the command channel. */
    fun rawCommand(bytes: ByteArray) {
        if (!bound) {
            emit(mapOf("type" to "status", "kind" to "raw", "failed" to "Pair the watch first."))
            return
        }
        write(bytes)
    }

    /** `03 01` + year(LE16) month day hour minute second weekday(Mon=0) 0(LE32) timezone(LE16). */
    private fun timeSyncPacket(): ByteArray {
        val c = java.util.Calendar.getInstance()
        val out = java.nio.ByteBuffer.allocate(16).order(java.nio.ByteOrder.LITTLE_ENDIAN)
        out.put(0x03).put(0x01)
        out.putShort(c.get(java.util.Calendar.YEAR).toShort())
        out.put((c.get(java.util.Calendar.MONTH) + 1).toByte())
        out.put(c.get(java.util.Calendar.DAY_OF_MONTH).toByte())
        out.put(c.get(java.util.Calendar.HOUR_OF_DAY).toByte())
        out.put(c.get(java.util.Calendar.MINUTE).toByte())
        out.put(c.get(java.util.Calendar.SECOND).toByte())
        val weekday = c.get(java.util.Calendar.DAY_OF_WEEK) - 2
        out.put((if (weekday < 0) 6 else weekday).toByte())
        out.putInt(0)
        // The SDK sends the timezone only for protocol family 3 (or device id 0x1fa).
        val sendsZone = ((protocolVersion and 0xFF00) shr 8) == 3 || deviceId == 0x1fa
        var minutes = c.timeZone.rawOffset / 60000
        if (sendsZone && protocolVersion < 0x313 && minutes <= 0) minutes += 0x5a0
        out.putShort(if (sendsZone) minutes.toShort() else 0)
        return out.array()
    }

    private fun handleShortReply(v: ByteArray) {
        val a = v[0].toInt() and 0xFF
        val b = v[1].toInt() and 0xFF
        fun u8(i: Int) = if (i < v.size) v[i].toInt() and 0xFF else 0
        fun u16(i: Int) = u8(i) or (u8(i + 1) shl 8)
        when {
            a == 0x02 && b == 0x05 && v.size >= 8 -> emit(mapOf(
                "type" to "status", "kind" to "battery",
                "batteryType" to u8(2), "voltage" to u16(3), "state" to u8(5), "level" to u8(6),
                "lastCharge" to listOf(u16(7), u8(9), u8(10), u8(11), u8(12), u8(13)),
            ))
            a == 0x02 && b == 0x11 && v.size >= 8 -> {
                var end = 8
                while (end < v.size && v[end].toInt() != 0 && v[end].toInt() != -1) end++
                emit(mapOf(
                    "type" to "status", "kind" to "version",
                    "sdk" to u8(2), "heartRate" to u8(3), "sleep" to u8(4), "step" to u8(5),
                    "gesture" to u8(6), "pcb" to u8(7),
                    "detail" to String(v, 8, end - 8, Charsets.UTF_8),
                ))
            }
            a == 0x03 && b == 0x01 -> emit(mapOf("type" to "status", "kind" to "time", "status" to u8(2)))
            a == 0x0A -> emit(mapOf("type" to "status", "kind" to "weather", "status" to u8(2)))
        }
    }

    // ---- Long commands (`0x33` framing), e.g. notifications ----

    private var longTimeout: Runnable? = null

    /**
     * Sends a framed long command, split into packets of `0x33` plus up to
     * `mtu - 4` message bytes, on the file channel. The caller builds the
     * message (magic, length, command, sequence, body, CRC).
     */
    fun sendLongCommand(message: ByteArray) {
        if (!bound) {
            emit(mapOf("type" to "notify", "stage" to "failed", "message" to "Pair the watch first."))
            return
        }
        val channel = fileChar
        if (channel == null || upload != null) {
            emit(mapOf("type" to "notify", "stage" to "failed", "message" to "The watch is busy."))
            return
        }
        val chunk = mtu - 4
        if (chunk <= 0) {
            emit(mapOf("type" to "notify", "stage" to "failed", "message" to "MTU too small."))
            return
        }
        longTimeout?.let(handler::removeCallbacks)
        val timeoutRunnable = Runnable {
            emit(mapOf("type" to "notify", "stage" to "failed", "message" to "The watch did not reply."))
        }
        longTimeout = timeoutRunnable
        handler.postDelayed(timeoutRunnable, LONG_REPLY_TIMEOUT_MS)
        var offset = 0
        while (offset < message.size) {
            val end = minOf(offset + chunk, message.size)
            val packet = ByteArray(1 + end - offset)
            packet[0] = LONG_PREFIX
            System.arraycopy(message, offset, packet, 1, end - offset)
            enqueue(channel, packet)
            offset = end
        }
        emit(mapOf("type" to "notify", "stage" to "sent", "bytes" to message.size))
    }

    /**
     * Long packets arrive as `33 DA AD DA AD ver len16 cmd16 seq16 payload crc16`. Replies to our
     * commands echo the command id; the watch also pushes events (quick reply) with sequence 0.
     */
    private fun handleLongPacket(v: ByteArray) {
        val framed = v.size >= 13 && v[1] == 0xDA.toByte() && v[2] == 0xAD.toByte() &&
            v[3] == 0xDA.toByte() && v[4] == 0xAD.toByte()
        if (!framed) return
        val cmd = (v[8].toInt() and 0xFF) or ((v[9].toInt() and 0xFF) shl 8)
        val seq = (v[10].toInt() and 0xFF) or ((v[11].toInt() and 0xFF) shl 8)
        val status = v[12].toInt() and 0xFF
        when (cmd) {
            0x000B -> {
                longTimeout?.let(handler::removeCallbacks)
                longTimeout = null
                emit(mapOf("type" to "notify", "stage" to "reply", "command" to cmd, "sequence" to seq,
                    "status" to status))
            }
            0x0015 -> emit(mapOf("type" to "presetReply", "sequence" to seq, "status" to status))
            0x0016 -> if (seq == 0) parseQuickReply(v) else log("rx", "event", "quick reply with sequence $seq")
            else -> log("rx", "long", "unhandled command 0x${cmd.toString(16)} seq $seq")
        }
    }

    /** Body: count, (flags<<4 | index), textLen, [numberLen], [number], text. */
    private fun parseQuickReply(v: ByteArray) {
        try {
            val count = v[12].toInt() and 0xFF
            val flags = v[13].toInt() and 0xFF
            val index = flags and 0x0F
            val hasNumber = (flags shr 4) == 0x0F
            val textLength = v[14].toInt() and 0xFF
            var pos = 15
            var number = ""
            if (hasNumber) {
                val numberLength = v[pos].toInt() and 0xFF
                pos++
                number = String(v, pos, minOf(numberLength, v.size - pos), Charsets.UTF_8).trimEnd('\u0000')
                pos += numberLength
            }
            val text = String(v, pos, minOf(textLength, v.size - pos), Charsets.UTF_8).trimEnd('\u0000')
            emit(mapOf("type" to "watchEvent", "kind" to "quickReply", "count" to count,
                "index" to index, "number" to number, "text" to text))
        } catch (e: Exception) {
            log("rx", "event", "malformed quick reply")
        }
    }

    /** Short events: `07 <category> <value>` (music keys, find phone, call buttons, sport state). */
    private fun handleWatchEvent(v: ByteArray) {
        emit(mapOf("type" to "watchEvent", "kind" to "short",
            "category" to (v[1].toInt() and 0xFF),
            "code" to if (v.size > 2) v[2].toInt() and 0xFF else -1))
    }

    // ---- Watch-face upload (docs/silence-os/08-watch-file-transfer.md) ----

    private enum class UStage { START_DIAL, START_FILE, WINDOW, DATA, VERIFY, FINISH_DIAL }

    private class Upload(val data: ByteArray, val name: String) {
        var stage = UStage.START_DIAL
        var window = 10
        var offset = 0
        var sum = 0L
        var packets = 0
        var lastProgress = -1
        val md5: MessageDigest = MessageDigest.getInstance("MD5")
    }

    /** Sends [data] as `cfg_res.watch` using the SDK's dial-sync sequence. Requires a successful bind. */
    fun startUpload(data: ByteArray, name: String = "cfg_res.watch") {
        if (!bound) {
            emit(mapOf("type" to "upload", "stage" to "failed", "message" to "Pair the watch first."))
            return
        }
        if (upload != null) return
        if (fileChar == null) {
            emit(mapOf("type" to "upload", "stage" to "failed", "message" to "The file channel was not found."))
            return
        }
        val u = Upload(data, name)
        upload = u
        uploadProgress("Starting dial transfer", 0)
        arm(UPLOAD_STEP_TIMEOUT_MS) { failUpload("The watch did not answer the start request.") }
        write(byteArrayOf(0x03, 0xE4.toByte(), 0x01, 0, 0, 0, 0))
    }

    /** Sends the SDK's apply-dial command for the photo dial (id 0). */
    fun applyDial() {
        if (!bound) return
        val bytes = ByteArray(20)
        bytes[0] = 0x03
        bytes[1] = 0xE6.toByte()
        write(bytes)
    }

    private fun handleUploadReply(u: Upload, v: ByteArray) {
        val a = v[0].toInt() and 0xFF
        val b = v[1].toInt() and 0xFF
        val status = if (v.size > 2) v[2].toInt() and 0xFF else -1
        when {
            u.stage == UStage.START_DIAL && a == 0x03 && b == 0xE4 -> {
                if (status != 1) return failUpload("The watch refused to start a dial transfer (status $status).")
                u.stage = UStage.START_FILE
                uploadProgress("Announcing file", 0)
                arm(UPLOAD_STEP_TIMEOUT_MS) { failUpload("The watch did not accept the file.") }
                val name = u.name.toByteArray()
                val size = u.data.size
                val packet = byteArrayOf(0xD1.toByte(), 0x01, 0x13) + le32(size) + byteArrayOf(0) + name
                enqueue(fileChar!!, packet)
            }
            u.stage == UStage.START_FILE && a == 0xD1 && b == 0x01 -> {
                when (status) {
                    0 -> {
                        u.stage = UStage.WINDOW
                        arm(UPLOAD_STEP_TIMEOUT_MS) { failUpload("The watch did not answer the window request.") }
                        enqueue(fileChar!!, byteArrayOf(0xD1.toByte(), 0x05, 0x0A))
                    }
                    0x7E -> {
                        uploadProgress("The watch already has this file", 100)
                        finishDial(u)
                    }
                    else -> failUpload("The watch rejected the file (status $status).")
                }
            }
            u.stage == UStage.WINDOW && a == 0xD1 && b == 0x05 -> {
                u.window = if (status > 0) status else 10
                u.stage = UStage.DATA
                clearTimeout()
                sendWindow(u)
            }
            u.stage == UStage.DATA && a == 0xD1 && b == 0x02 -> handleAck(u, v, status)
            u.stage == UStage.VERIFY && a == 0xD1 && b == 0x03 -> {
                if (status != 0) return failUpload("The watch rejected the file check (status $status).")
                finishDial(u)
            }
            u.stage == UStage.FINISH_DIAL && a == 0x03 && b == 0xE4 -> {
                clearTimeout()
                upload = null
                if (status == 1) {
                    emit(mapOf("type" to "upload", "stage" to "done"))
                } else {
                    emit(mapOf("type" to "upload", "stage" to "failed",
                        "message" to "The watch did not confirm the dial (status $status)."))
                }
            }
        }
    }

    /** Queues one acknowledgement window of data packets. */
    private fun sendWindow(u: Upload) {
        val chunk = mtu - 6
        if (chunk <= 0) return failUpload("MTU too small for file transfer.")
        var sentInWindow = 0
        while (sentInWindow < u.window && u.offset < u.data.size) {
            val end = minOf(u.offset + chunk, u.data.size)
            val packet = ByteArray(3 + end - u.offset)
            packet[0] = 0xD1.toByte()
            packet[1] = 0x02
            System.arraycopy(u.data, u.offset, packet, 3, end - u.offset)
            for (i in u.offset until end) u.sum += u.data[i].toLong() and 0xFF
            u.offset = end
            enqueue(fileChar!!, packet)
            sentInWindow++
            u.packets++
        }
        val percent = (u.offset.toLong() * 100 / u.data.size).toInt()
        if (percent != u.lastProgress) {
            u.lastProgress = percent
            uploadProgress("Sending", percent)
        }
        if (u.offset >= u.data.size && u.packets % u.window != 0) {
            // The SDK does not wait for an acknowledgement after a partial final window.
            sendVerify(u)
        } else {
            arm(UPLOAD_ACK_TIMEOUT_MS) { failUpload("The watch stopped acknowledging data at ${u.offset} bytes.") }
        }
    }

    private fun handleAck(u: Upload, v: ByteArray, status: Int) {
        clearTimeout()
        when (status) {
            0x00 -> {
                if (v.size >= 11) {
                    val sum = le32At(v, 3)
                    val off = le32At(v, 7)
                    if (sum != (u.sum and 0xFFFFFFFFL) || off != u.offset.toLong()) {
                        log("rx", "ack", "mismatch: watch sum=$sum offset=$off, sent sum=${u.sum and 0xFFFFFFFFL} offset=${u.offset}")
                    }
                }
                if (u.offset >= u.data.size) sendVerify(u) else sendWindow(u)
            }
            0x7E -> sendVerify(u)
            0x7F -> {
                val off = if (v.size >= 11) le32At(v, 7).toInt() else 0
                if (off < 0 || off > u.data.size) return failUpload("The watch asked to resume at an invalid offset ($off).")
                log("rx", "ack", "resume at $off")
                u.offset = off
                u.sum = 0
                for (i in 0 until off) u.sum += u.data[i].toLong() and 0xFF
                u.packets = 0
                sendWindow(u)
            }
            else -> failUpload("The watch reported a transfer error (status $status).")
        }
    }

    private fun sendVerify(u: Upload) {
        u.stage = UStage.VERIFY
        uploadProgress("Verifying", 100)
        val md5 = u.md5.digest(u.data).joinToString("") { "%02x".format(it) }
        val packet = byteArrayOf(0xD1.toByte(), 0x03) + le32((u.data.fold(0L) { acc, b -> acc + (b.toLong() and 0xFF) } and 0xFFFFFFFFL).toInt()) + md5.toByteArray()
        arm(UPLOAD_VERIFY_TIMEOUT_MS) { failUpload("The watch did not finish verifying the file.") }
        enqueue(fileChar!!, packet)
    }

    private fun finishDial(u: Upload) {
        u.stage = UStage.FINISH_DIAL
        uploadProgress("Finishing", 100)
        arm(UPLOAD_FINISH_TIMEOUT_MS) { failUpload("The watch did not confirm the finished dial.") }
        write(byteArrayOf(0x03, 0xE4.toByte(), 0x03, 0, 0, 0, 0))
    }

    private fun uploadProgress(message: String, percent: Int) =
        emit(mapOf("type" to "upload", "stage" to "progress", "message" to message, "percent" to percent))

    private fun failUpload(message: String) {
        clearTimeout()
        upload = null
        writeQueue.clear()
        emit(mapOf("type" to "upload", "stage" to "failed", "message" to message))
    }

    private fun le32(v: Int) = byteArrayOf(v.toByte(), (v shr 8).toByte(), (v shr 16).toByte(), (v shr 24).toByte())

    private fun le32At(b: ByteArray, i: Int): Long =
        (b[i].toLong() and 0xFF) or ((b[i + 1].toLong() and 0xFF) shl 8) or
            ((b[i + 2].toLong() and 0xFF) shl 16) or ((b[i + 3].toLong() and 0xFF) shl 24)

    private fun arm(ms: Long, action: () -> Unit) {
        clearTimeout()
        val r = Runnable { action() }
        timeout = r
        handler.postDelayed(r, ms)
    }

    private fun clearTimeout() {
        timeout?.let(handler::removeCallbacks)
        timeout = null
    }

    private fun progress(message: String) =
        emit(mapOf("type" to "pair", "stage" to "progress", "message" to message))

    private fun fail(message: String) {
        clearTimeout()
        stage = Stage.IDLE
        pendingDescriptors.clear()
        emit(mapOf("type" to "pair", "stage" to "failed", "message" to message))
    }

    private fun log(dir: String, channel: String, hex: String) =
        emit(mapOf("type" to "protocol", "dir" to dir, "channel" to channel, "hex" to hex))

    private fun ByteArray.hex() = joinToString(" ") { "%02x".format(it) }

    companion object {
        private fun uuid(short: String) = UUID.fromString("0000$short-0000-1000-8000-00805f9b34fb")
        private val SERVICE_27F0 = uuid("27f0")
        private val SERVICE_0AF0 = uuid("0af0")
        private val TOUCHGUI_SERVICES = setOf(SERVICE_27F0, SERVICE_0AF0, uuid("2760"))
        private val CHAR_27F1 = uuid("27f1")
        private val CHAR_0AF1 = uuid("0af1")
        private val CHAR_27F6 = uuid("27f6")
        private val CHAR_0AF6 = uuid("0af6")
        private val CCCD = uuid("2902")
        private const val LONG_PREFIX: Byte = 0x33
        private const val LONG_REPLY_TIMEOUT_MS = 15_000L
        private const val MAX_WRITE_RETRIES = 3
        private const val WRITE_RETRY_MS = 50L
        private const val UPLOAD_STEP_TIMEOUT_MS = 15_000L
        private const val UPLOAD_ACK_TIMEOUT_MS = 8_000L
        private const val UPLOAD_VERIFY_TIMEOUT_MS = 30_000L
        private const val UPLOAD_FINISH_TIMEOUT_MS = 60_000L
        private const val REQUESTED_MTU = 247
        private const val MTU_TIMEOUT_MS = 3_000L
        private const val STEP_TIMEOUT_MS = 6_000L
        private const val BIND_TIMEOUT_MS = 60_000L
    }
}
