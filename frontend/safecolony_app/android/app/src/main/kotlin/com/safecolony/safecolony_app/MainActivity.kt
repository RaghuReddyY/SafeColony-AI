package com.safecolony.safecolony_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "safecolony/native_apps"
    private val phonePePackage = "com.phonepe.app"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openPhonePe" -> result.success(openPhonePe())
                    else -> result.notImplemented()
                }
            }
    }

    private fun openPhonePe(): Boolean {
        return try {
            val intent: Intent? = packageManager.getLaunchIntentForPackage(phonePePackage)
            if (intent == null) false
            else {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            }
        } catch (_: Exception) { false }
    }
}
