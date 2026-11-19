package com.krishna.applock

import android.content.Context
import android.content.SharedPreferences

// Saves the list of locked apps and the master on/off switch in Android's
// SharedPreferences (a small private key-value file inside the app).
//
// Why here and not in Flutter? The watcher (LockAccessibilityService) runs
// in the background, even when the Flutter UI isn't open. It needs to read
// this list instantly, without starting Flutter.
//
// "object" in Kotlin = a class with exactly one shared instance.
object LockedAppsStore {
    private const val FILE = "app_lock_native"
    private const val KEY_LOCKED = "locked_packages"
    private const val KEY_PROTECTION_ON = "protection_on"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    // Package names of the locked apps, e.g. "com.whatsapp".
    fun getLocked(context: Context): Set<String> =
        // Android says: never change the set it gives back, so we copy it.
        prefs(context).getStringSet(KEY_LOCKED, emptySet())?.toSet() ?: emptySet()

    fun setLocked(context: Context, packages: Collection<String>) {
        // apply() saves in the background, so the caller doesn't wait.
        prefs(context).edit().putStringSet(KEY_LOCKED, packages.toSet()).apply()
    }

    // The master switch on Home. On by default.
    fun isProtectionOn(context: Context): Boolean =
        prefs(context).getBoolean(KEY_PROTECTION_ON, true)

    fun setProtectionOn(context: Context, on: Boolean) {
        prefs(context).edit().putBoolean(KEY_PROTECTION_ON, on).apply()
    }
}
