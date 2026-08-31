package com.bookey.bookey

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val KIOSK_CHANNEL = "com.bookey.bookey/kiosk"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLockTask" -> {
                        try {
                            startLockTask()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOCK_TASK_ERROR", e.message, null)
                        }
                    }
                    "stopLockTask" -> {
                        try {
                            stopLockTask()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("UNLOCK_TASK_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
