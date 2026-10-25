package dev.silence.silence_app

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * Creates the single Flutter engine and Bluetooth host for the process, so the watch
 * connection and notification relay keep running without any activity on screen.
 */
class SilenceApp : Application() {
    override fun onCreate() {
        super.onCreate()
        val engine = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(engine)
        host = BleHost(this).also { it.attach(engine.dartExecutor.binaryMessenger) }
        SmartReplyEngine().attach(engine.dartExecutor.binaryMessenger)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    companion object {
        const val ENGINE_ID = "silence"
        lateinit var host: BleHost
            private set
    }
}
