package dev.silence.silence_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/** Shows the Flutter UI attached to the process-wide engine owned by [SilenceApp]. */
class MainActivity : FlutterActivity() {
    override fun getCachedEngineId(): String = SilenceApp.ENGINE_ID

    override fun shouldDestroyEngineWithHost(): Boolean = false

    // Plugins are registered once when the engine is created.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {}

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        SilenceApp.host.activity = this
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_REQUEST)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        SilenceApp.host.onPermissionsResult(requestCode)
    }

    override fun onDestroy() {
        if (SilenceApp.host.activity === this) SilenceApp.host.activity = null
        super.onDestroy()
    }

    private companion object {
        const val NOTIFICATION_PERMISSION_REQUEST = 4103
    }
}
