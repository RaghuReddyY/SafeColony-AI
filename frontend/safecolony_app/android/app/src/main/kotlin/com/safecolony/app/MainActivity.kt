package com.safecolony.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "safecolony/native_apps"
        const val PHONEPE_PACKAGE = "com.phonepe.app"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openPhonePe" -> result.success(openPhonePe())
                else -> result.notImplemented()
            }
        }
    }

    private fun openPhonePe(): Boolean {
        return try {
            val launchIntent: Intent =
                packageManager.getLaunchIntentForPackage(PHONEPE_PACKAGE)
                    ?: return false

            startActivity(launchIntent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
