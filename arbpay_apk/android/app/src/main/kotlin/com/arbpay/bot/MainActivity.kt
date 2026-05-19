package com.arbpay.bot

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.arbpay.bot/icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val isDark = call.argument<Boolean>("isDark") ?: true
                        setLauncherIcon(isDark)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setLauncherIcon(isDark: Boolean) {
        val pm = packageManager
        val pkg = packageName

        val darkAlias  = ComponentName(pkg, "$pkg.MainActivityDark")
        val lightAlias = ComponentName(pkg, "$pkg.MainActivityLight")

        // Enable the matching alias, disable the other
        pm.setComponentEnabledSetting(
            if (isDark) darkAlias else lightAlias,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
        pm.setComponentEnabledSetting(
            if (isDark) lightAlias else darkAlias,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
    }
}
