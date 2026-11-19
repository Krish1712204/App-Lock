package com.krishna.applock

import android.content.Context
import android.content.SharedPreferences

// All App Lock settings, saved in native SharedPreferences.
// They live in Kotlin (not Dart) because the watcher and the lock screen
// engine need them too, even when the normal App Lock screens aren't open.
//
// Dart reads/writes them with the "getSettings" / "setSetting" methods
// in NativeChannel.kt. The key names below are the same in Dart
// (lib/services/settings_service.dart).
object SettingsStore {
    private const val FILE = "app_lock_settings"

    const val FINGERPRINT = "fingerprintUnlock" // use fingerprint on the lock screen
    const val RELOCK_SECONDS = "relockSeconds" // 0 = right away, 60, 300
    const val LOCK_ON_SCREEN_OFF = "lockOnScreenOff"
    const val LOCK_SYSTEM_APPS = "lockSystemApps" // Settings, Play Store, installer
    const val HIDE_RECENTS = "hideRecents" // FLAG_SECURE on App Lock's screens

    // Every setting with its default value.
    private val defaults: Map<String, Any> = mapOf(
        FINGERPRINT to true,
        RELOCK_SECONDS to 0,
        LOCK_ON_SCREEN_OFF to true,
        LOCK_SYSTEM_APPS to false,
        HIDE_RECENTS to true,
    )

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    // All settings at once, for Dart.
    fun all(context: Context): Map<String, Any> {
        val p = prefs(context)
        return defaults.mapValues { (key, default) ->
            when (default) {
                is Boolean -> p.getBoolean(key, default)
                is Int -> p.getInt(key, default)
                else -> default
            }
        }
    }

    // Saves one setting. Unknown keys and wrong types are ignored.
    fun set(context: Context, key: String, value: Any?) {
        if (key !in defaults) return
        val editor = prefs(context).edit()
        when (value) {
            is Boolean -> editor.putBoolean(key, value)
            is Int -> editor.putInt(key, value)
            else -> return
        }
        editor.apply()
    }

    fun isOn(context: Context, key: String): Boolean =
        prefs(context).getBoolean(key, defaults[key] as? Boolean ?: false)

    fun relockDelayMs(context: Context): Long =
        prefs(context).getInt(RELOCK_SECONDS, 0) * 1000L
}
