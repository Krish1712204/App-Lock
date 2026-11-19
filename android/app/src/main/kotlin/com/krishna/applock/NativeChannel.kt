package com.krishna.applock

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// The bridge between Flutter (Dart) and Kotlin.
//
// Dart calls e.g. `channel.invokeMethod('setLockedApps', {...})`, and
// the matching branch below runs in Kotlin. `result.success(x)` sends x
// back to Dart as the answer.
//
// It's in its own file (not inside MainActivity) so that Phase 4's lock
// screen engine can register the same channel.
object NativeChannel {
    const val NAME = "app_lock/native"

    // [context] is MainActivity: settings pages are opened from it, so Back
    // in Android settings returns straight to App Lock.
    fun register(context: Context, messenger: BinaryMessenger) {
        // applicationContext lives as long as the app, so it's safe to keep.
        val appContext = context.applicationContext

        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    // Drawing ~100 icons takes a moment: do it on a background
                    // thread, then answer Dart on the main thread (required).
                    Thread {
                        val apps = InstalledApps.load(appContext)
                        Handler(Looper.getMainLooper()).post { result.success(apps) }
                    }.start()
                }

                "getLockedApps" ->
                    result.success(LockedAppsStore.getLocked(appContext).toList())

                "setLockedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    LockedAppsStore.setLocked(appContext, packages)
                    result.success(null)
                }

                "isProtectionOn" ->
                    result.success(LockedAppsStore.isProtectionOn(appContext))

                "setProtectionOn" -> {
                    val on = call.argument<Boolean>("on") ?: true
                    LockedAppsStore.setProtectionOn(appContext, on)
                    result.success(null)
                }

                "getSettings" ->
                    result.success(SettingsStore.all(appContext))

                "setSetting" -> {
                    val key = call.argument<String>("key") ?: ""
                    val value = call.argument<Any>("value")
                    SettingsStore.set(appContext, key, value)
                    // Apply "Hide previews" right away to the open screen.
                    if (key == SettingsStore.HIDE_RECENTS) {
                        (context as? Activity)?.let { SecureScreen.apply(it) }
                    }
                    result.success(null)
                }

                "getPermissions" ->
                    result.success(PermissionsHelper.status(appContext))

                "openPermission" -> {
                    val name = call.argument<String>("name") ?: "appInfo"
                    result.success(PermissionsHelper.open(context, name))
                }

                else -> result.notImplemented() // unknown method name
            }
        }
    }
}
