package com.foundersscout.founders_scout

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "founders_scout/config"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGoogleMapsApiKey" -> {
                    val apiKey = applicationContext.packageManager
                        .getApplicationInfo(applicationContext.packageName, android.content.pm.PackageManager.GET_META_DATA)
                        .metaData
                        ?.getString("com.google.android.geo.API_KEY")
                        .orEmpty()
                    result.success(apiKey)
                }
                else -> result.notImplemented()
            }
        }
    }
}
