package dev.silence.silence_app

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Owns scanning, the GATT connection and the TouchGUI session for the whole app process,
 * independent of any activity, and exposes them to Dart over method/event channels.
 */
class BleHost(private val context: Context) {
    /** The visible activity, used only to show permission dialogs. */
    var activity: Activity? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var activeScanCallback: ScanCallback? = null
    private var scanTimeout: Runnable? = null
    private var connectionTimeout: Runnable? = null
    private var discoveryTimeout: Runnable? = null
    private var currentDeviceId: String? = null
    private var currentGatt: BluetoothGatt? = null
    private var connected = false
    private var discoveryInProgress = false
    private var pendingPermissionOperation: PendingOperation? = null
    private var destroyed = false
    private var session: TouchGuiSession? = null
    private var currentDeviceName: String? = null

    private data class PendingOperation(val kind: String, val deviceId: String? = null)

    fun attach(messenger: BinaryMessenger) {
        NotificationBridge.sink = { event -> mainHandler.post { emit(event) } }
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(::handleMethod)
        EventChannel(messenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    pendingPermissionOperation = null
                    stopScan()
                    releaseConnection(notify = false)
                }
            })
    }

    private fun adapter(): BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    private fun emit(event: Map<String, Any?>) {
        if (event["type"] == "pair" && event["stage"] == "bindResult" && event["success"] == true) {
            startRelayService()
        }
        if (!destroyed) eventSink?.success(event)
    }

    /** Keeps the process alive while the watch is bound so notifications keep flowing. */
    private fun startRelayService() {
        try {
            context.startForegroundService(
                Intent(context, RelayService::class.java).putExtra(RelayService.EXTRA_DEVICE, currentDeviceName)
            )
        } catch (_: Exception) {
            // Android may refuse a foreground start from the background; the connection still works.
        }
    }

    private fun stopRelayService() {
        try {
            context.stopService(Intent(context, RelayService::class.java))
        } catch (_: Exception) {
        }
    }

    /** Called from the service notification's Release action. */
    fun release() {
        mainHandler.post {
            pendingPermissionOperation = null
            stopScan()
            releaseConnection(notify = true)
        }
    }

    private fun error(message: String) = emit(mapOf("type" to "error", "message" to message))

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getAdapterState" -> {
                    val bluetooth = adapter()
                    val supported = bluetooth != null && context.packageManager.hasSystemFeature(
                        PackageManager.FEATURE_BLUETOOTH_LE
                    )
                    val canQuery = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                        context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
                        PackageManager.PERMISSION_GRANTED
                    result.success(mapOf(
                        "supported" to supported,
                        "enabled" to (canQuery && bluetooth?.isEnabled == true),
                        "permissionRequired" to !canQuery
                    ))
                }
                "scan" -> startWithPermissions(PendingOperation("scan"), result)
                "stopScan" -> {
                    if (pendingPermissionOperation?.kind == "scan") pendingPermissionOperation = null
                    stopScan()
                    result.success(null)
                }
                "connect" -> {
                    val id = call.argument<String>("id")
                    if (id == null || !BluetoothAdapter.checkBluetoothAddress(id)) {
                        result.error("INVALID_DEVICE", "A valid Bluetooth device address is required.", null)
                    } else {
                        startWithPermissions(PendingOperation("connect", id), result)
                    }
                }
                "releaseDevice" -> {
                    // Cancel permission-resume and all BLE ownership, including in-flight connects.
                    pendingPermissionOperation = null
                    stopScan()
                    releaseConnection(notify = true)
                    result.success(null)
                }
                "openBluetoothSettings" -> {
                    context.startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                }
                "disconnect" -> {
                    if (pendingPermissionOperation?.kind == "connect") pendingPermissionOperation = null
                    releaseConnection(notify = true)
                    result.success(null)
                }
                "uploadWatchFile" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val active = session
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("BAD_ARGUMENTS", "No file data.", null)
                    } else if (active == null) {
                        error("Pair the watch before sending a watch face.")
                        result.success(null)
                    } else {
                        active.startUpload(bytes)
                        result.success(null)
                    }
                }
                "notificationAccess" -> result.success(notificationAccessGranted())
                "openNotificationAccessSettings" -> {
                    context.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                }
                "replyToNotification" -> {
                    val key = call.argument<String>("key")
                    val text = call.argument<String>("text")
                    result.success(
                        key != null && text != null && ReplyStore.reply(context, key, text)
                    )
                }
                "mediaControl" -> {
                    mediaControl(call.argument<String>("action"))
                    result.success(null)
                }
                "rawCommand" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val active = session
                    if (bytes == null || bytes.isEmpty() || active == null) {
                        error("Pair the watch before sending commands.")
                    } else {
                        active.rawCommand(bytes)
                    }
                    result.success(null)
                }
                "statusCommand" -> {
                    val kind = call.argument<String>("kind")
                    val active = session
                    if (kind == null || active == null) {
                        error("Pair the watch before querying it.")
                    } else {
                        active.statusCommand(kind)
                    }
                    result.success(null)
                }
                "sendLongCommand" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val active = session
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("BAD_ARGUMENTS", "No command data.", null)
                    } else if (active == null) {
                        error("Pair the watch before sending commands.")
                        result.success(null)
                    } else {
                        active.sendLongCommand(bytes)
                        result.success(null)
                    }
                }
                "applyDial" -> {
                    session?.applyDial()
                    result.success(null)
                }
                "pair" -> {
                    startPairing()
                    result.success(null)
                }
                "discoverServices" -> {
                    discoverServices()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: SecurityException) {
            error("Bluetooth permission is missing. Grant Nearby devices access and try again.")
            result.error("PERMISSION_DENIED", e.message, null)
        } catch (e: IllegalArgumentException) {
            error("The Bluetooth operation could not be started: ${e.message}")
            result.error("INVALID_ARGUMENT", e.message, null)
        } catch (e: IllegalStateException) {
            error("Bluetooth is not ready: ${e.message}")
            result.error("BLUETOOTH_UNAVAILABLE", e.message, null)
        }
    }

    /** Applies a watch music/volume key to the phone. */
    private fun mediaControl(action: String?) {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as? android.media.AudioManager ?: return
        fun key(code: Int) {
            audio.dispatchMediaKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, code))
            audio.dispatchMediaKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, code))
        }
        when (action) {
            "play" -> key(android.view.KeyEvent.KEYCODE_MEDIA_PLAY)
            "pause" -> key(android.view.KeyEvent.KEYCODE_MEDIA_PAUSE)
            "next" -> key(android.view.KeyEvent.KEYCODE_MEDIA_NEXT)
            "previous" -> key(android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            "volumeUp" -> audio.adjustStreamVolume(
                android.media.AudioManager.STREAM_MUSIC,
                android.media.AudioManager.ADJUST_RAISE,
                android.media.AudioManager.FLAG_SHOW_UI
            )
            "volumeDown" -> audio.adjustStreamVolume(
                android.media.AudioManager.STREAM_MUSIC,
                android.media.AudioManager.ADJUST_LOWER,
                android.media.AudioManager.FLAG_SHOW_UI
            )
        }
    }

    private fun notificationAccessGranted(): Boolean {
        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
            ?: return false
        return enabled.split(":").any { it.startsWith("${context.packageName}/") }
    }

    private fun permissionHelp(): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) "Nearby devices" else "Location"

    private fun requiredPermissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    private fun startWithPermissions(operation: PendingOperation, result: MethodChannel.Result) {
        if (pendingPermissionOperation != null) {
            result.error("PERMISSION_PENDING", "Please finish the current Bluetooth permission request.", null)
            return
        }
        if (adapter() == null || !context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            result.error("UNSUPPORTED", "Bluetooth LE is not available on this device.", null)
            return
        }
        val missing = requiredPermissions().filter {
            context.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            val host = activity
            if (host == null) {
                result.error(
                    "PERMISSION_NEEDS_SCREEN",
                    "Open Silence and allow ${permissionHelp()} access, then try again.",
                    null
                )
                return
            }
            pendingPermissionOperation = operation
            host.requestPermissions(missing.toTypedArray(), PERMISSION_REQUEST)
        } else {
            execute(operation)
        }
        // Completion is represented by the event stream. No method result waits on a dialog.
        result.success(null)
    }

    fun onPermissionsResult(requestCode: Int) {
        if (requestCode != PERMISSION_REQUEST) return
        val operation = pendingPermissionOperation ?: return
        pendingPermissionOperation = null
        if (requiredPermissions().all { context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }) {
            try {
                execute(operation)
            } catch (_: SecurityException) {
                error("Bluetooth permission is missing. Grant Nearby devices access and try again.")
            } catch (e: IllegalStateException) {
                error("Bluetooth is not ready: ${e.message}")
            } catch (e: IllegalArgumentException) {
                error("The Bluetooth operation could not be started: ${e.message}")
            }
        } else {
            error("Bluetooth access was denied. Enable ${permissionHelp()} access in Android settings and try again.")
            emit(mapOf("type" to "scanState", "scanning" to false))
        }
    }

    private fun execute(operation: PendingOperation) {
        if (destroyed) return
        val bluetooth = adapter()
        if (bluetooth == null || !bluetooth.isEnabled) {
            error("Turn on Bluetooth, then try again.")
            emit(mapOf("type" to "scanState", "scanning" to false))
            return
        }
        when (operation.kind) {
            "scan" -> scan(bluetooth)
            "connect" -> connect(bluetooth, requireNotNull(operation.deviceId))
        }
    }

    @SuppressLint("MissingPermission")
    private fun scan(bluetooth: BluetoothAdapter) {
        stopScan()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            val location = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            val locationEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                location?.isLocationEnabled == true
            } else {
                location?.isProviderEnabled(LocationManager.GPS_PROVIDER) == true ||
                    location?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) == true
            }
            if (!locationEnabled) {
                error("Enable Android Location services for Bluetooth discovery on this Android version.")
                return
            }
        }
        val scanner = bluetooth.bluetoothLeScanner
        if (scanner == null) {
            error("The Bluetooth LE scanner is unavailable. Check that Bluetooth is enabled.")
            return
        }
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                mainHandler.post {
                    if (activeScanCallback !== this || destroyed) return@post
                    try {
                        val name = result.scanRecord?.deviceName?.takeIf { it.isNotBlank() }
                            ?: result.device.name?.takeIf { it.isNotBlank() } ?: "Unnamed device"
                        emit(mapOf("type" to "device", "id" to result.device.address,
                            "name" to name, "rssi" to result.rssi))
                    } catch (_: SecurityException) {
                        stopScan()
                        error("Bluetooth permission was revoked during discovery.")
                    }
                }
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                results.forEach { onScanResult(0, it) }
            }

            override fun onScanFailed(errorCode: Int) {
                mainHandler.post {
                    if (activeScanCallback !== this || destroyed) return@post
                    stopScan()
                    error("Bluetooth discovery failed (code $errorCode). Wait a moment and try again.")
                }
            }
        }
        activeScanCallback = callback
        try {
            scanner.startScan(null, ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(), callback)
            emit(mapOf("type" to "scanState", "scanning" to true))
            val timeout = Runnable { if (activeScanCallback === callback) stopScan() }
            scanTimeout = timeout
            mainHandler.postDelayed(timeout, SCAN_DURATION_MS)
        } catch (e: Exception) {
            stopScan()
            if (e is SecurityException || e is IllegalStateException) {
                error("Bluetooth discovery could not start. Check Bluetooth and app permissions.")
            } else {
                throw e
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun stopScan() {
        scanTimeout?.let(mainHandler::removeCallbacks)
        scanTimeout = null
        val callback = activeScanCallback
        activeScanCallback = null
        if (callback != null) {
            try {
                adapter()?.bluetoothLeScanner?.stopScan(callback)
            } catch (_: SecurityException) {
                // Permission can be revoked while the scan is active.
            } catch (_: IllegalStateException) {
                // Adapter may have been switched off.
            }
        }
        emit(mapOf("type" to "scanState", "scanning" to false))
    }

    @SuppressLint("MissingPermission")
    private fun connect(bluetooth: BluetoothAdapter, id: String) {
        stopScan()
        releaseConnection(notify = true)
        val device = bluetooth.getRemoteDevice(id)
        val name = device.name?.takeIf { it.isNotBlank() } ?: "Unnamed device"
        currentDeviceId = id
        currentDeviceName = name
        emit(mapOf("type" to "connection", "state" to "connecting", "id" to id, "name" to name))
        val callback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                mainHandler.post {
                    if (currentGatt !== gatt || destroyed) return@post
                    when {
                        status != BluetoothGatt.GATT_SUCCESS -> {
                            error("Bluetooth connection failed (GATT status $status).")
                            releaseConnection(notify = true)
                        }
                        newState == BluetoothProfile.STATE_CONNECTED -> {
                            connectionTimeout?.let(mainHandler::removeCallbacks)
                            connectionTimeout = null
                            connected = true
                            emit(mapOf("type" to "connection", "state" to "connected",
                                "id" to id, "name" to name))
                            discoverServices()
                        }
                        newState == BluetoothProfile.STATE_DISCONNECTED -> releaseConnection(notify = true)
                    }
                }
            }

            override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
                mainHandler.post { if (currentGatt === gatt) session?.onDescriptorWrite(status) }
            }

            override fun onCharacteristicWrite(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
                mainHandler.post { if (currentGatt === gatt) session?.onCharacteristicWrite(status) }
            }

            override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
                mainHandler.post { if (currentGatt === gatt) session?.onMtuChanged(mtu, status) }
            }

            @Deprecated("Used below API 33")
            override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
                @Suppress("DEPRECATION")
                val value = characteristic.value ?: return
                mainHandler.post { if (currentGatt === gatt) session?.onNotification(characteristic, value) }
            }

            override fun onCharacteristicChanged(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray,
            ) {
                mainHandler.post { if (currentGatt === gatt) session?.onNotification(characteristic, value) }
            }

            override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                mainHandler.post {
                    if (currentGatt !== gatt || destroyed) return@post
                    discoveryInProgress = false
                    discoveryTimeout?.let(mainHandler::removeCallbacks)
                    discoveryTimeout = null
                    if (status != BluetoothGatt.GATT_SUCCESS) {
                        error("Service discovery failed (GATT status $status).")
                        return@post
                    }
                    emit(mapOf("type" to "services", "id" to id, "services" to gatt.services.map {
                        mapOf("uuid" to it.uuid.toString(), "characteristicCount" to it.characteristics.size)
                    }))
                }
            }
        }
        currentGatt = device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
        if (currentGatt == null) {
            currentDeviceId = null
            error("Android could not create a Bluetooth connection.")
            emit(mapOf("type" to "connection", "state" to "disconnected", "id" to id, "name" to name))
            return
        }
        val pendingGatt = currentGatt
        val timeout = Runnable {
            if (currentGatt === pendingGatt && !connected) {
                error("The watch did not connect within 20 seconds. Release its connection from NoiseFit and try again.")
                releaseConnection(notify = true)
            }
        }
        connectionTimeout = timeout
        mainHandler.postDelayed(timeout, CONNECTION_TIMEOUT_MS)
    }

    /** User-initiated TouchGUI bind; the only thing Silence ever writes to the watch. */
    private fun startPairing() {
        val gatt = currentGatt
        if (gatt == null || !connected || gatt.services.isEmpty()) {
            error("Connect and let service discovery finish before pairing.")
            return
        }
        session?.cancel()
        session = TouchGuiSession(gatt, mainHandler, ::emit).also { it.start() }
    }

    @SuppressLint("MissingPermission")
    private fun discoverServices() {
        val gatt = currentGatt
        if (gatt == null || !connected) {
            error("Connect a device before discovering its services.")
            return
        }
        if (discoveryInProgress) return
        try {
            discoveryInProgress = gatt.discoverServices()
            if (!discoveryInProgress) {
                error("Android could not start service discovery. Try reconnecting.")
            } else {
                val timeout = Runnable {
                    if (currentGatt === gatt && discoveryInProgress) {
                        error("Service discovery timed out. Reconnect the watch and try again.")
                        releaseConnection(notify = true)
                    }
                }
                discoveryTimeout = timeout
                mainHandler.postDelayed(timeout, SERVICE_DISCOVERY_TIMEOUT_MS)
            }
        } catch (_: SecurityException) {
            discoveryInProgress = false
            error("Bluetooth permission is missing. Grant Nearby devices access and reconnect.")
        }
    }

    @SuppressLint("MissingPermission")
    private fun releaseConnection(notify: Boolean) {
        connectionTimeout?.let(mainHandler::removeCallbacks)
        connectionTimeout = null
        discoveryTimeout?.let(mainHandler::removeCallbacks)
        discoveryTimeout = null
        session?.cancel()
        session = null
        stopRelayService()
        val gatt = currentGatt
        val id = currentDeviceId
        currentDeviceId = null
        currentGatt = null
        connected = false
        discoveryInProgress = false
        if (gatt != null) {
            try {
                gatt.disconnect()
            } catch (_: SecurityException) {
                // Always attempt close, even after permission revocation.
            } finally {
                try { gatt.close() } catch (_: SecurityException) { }
            }
            if (notify) emit(mapOf("type" to "connection", "state" to "disconnected", "id" to id))
        }
    }

    fun shutdown() {
        NotificationBridge.sink = null
        pendingPermissionOperation = null
        stopScan()
        releaseConnection(notify = false)
        destroyed = true
        eventSink = null
        mainHandler.removeCallbacksAndMessages(null)
    }

    companion object {
        private const val METHOD_CHANNEL = "dev.silence/ble"
        private const val EVENT_CHANNEL = "dev.silence/ble_events"
        private const val PERMISSION_REQUEST = 4102
        private const val SCAN_DURATION_MS = 10_000L
        private const val CONNECTION_TIMEOUT_MS = 20_000L
        private const val SERVICE_DISCOVERY_TIMEOUT_MS = 15_000L
    }
}
