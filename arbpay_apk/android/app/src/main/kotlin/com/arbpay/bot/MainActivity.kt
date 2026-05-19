package com.arbpay.bot

import android.content.ComponentName
import android.content.pm.PackageManager
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.arbpay.bot/icon"

    // Pending icon switch — applied when app goes to background
    private var pendingIsDark: Boolean? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Observe app lifecycle — apply icon switch when app backgrounds
        ProcessLifecycleOwner.get().lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStop(owner: LifecycleOwner) {
                pendingIsDark?.let {
                    applyLauncherIcon(it)
                    pendingIsDark = null
                }
            }
        })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val isDark = call.argument<Boolean>("isDark") ?: true
                        // Queue the switch — will apply when user leaves the app
                        pendingIsDark = isDark
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun applyLauncherIcon(isDark: Boolean) {
        val pm = packageManager
        val pkg = packageName

        val darkAlias  = ComponentName(pkg, "$pkg.MainActivityDark")
        val lightAlias = ComponentName(pkg, "$pkg.MainActivityLight")

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
