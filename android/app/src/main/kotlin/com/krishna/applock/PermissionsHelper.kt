package com.krishna.applock

import android.annotation.SuppressLint
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.hardware.biometrics.BiometricManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

// Checks the real status of App Lock's permissions, and opens the right
// Android settings page for each one.
// (Fingerprint status is checked in Dart with local_auth, so it's not here.)
object PermissionsHelper {

    // Everything the Permissions screen and Health check need, in one map.
    fun status(context: Context): Map<String, Boolean> = mapOf(
        "accessibility" to isAccessibilityEnabled(context), // switched on in Settings
        "watcherRunning" to LockAccessibilityService.isRunning, // actually running now
        "overlay" to Settings.canDrawOverlays(context),
        "battery" to isBatteryUnrestricted(context),
    )

    // Android keeps the enabled accessibility services in one long text:
    // "com.a/.ServiceA:com.b/.ServiceB". We look for ours in that list.
    private fun isAccessibilityEnabled(context: Context): Boolean {
        val ours = ComponentName(context, LockAccessibilityService::class.java)
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == ours }
    }

    // "Ignoring battery optimizations" is what the Battery → Unrestricted
    // option sets: Android won't pause or close App Lock to save battery.
    private fun isBatteryUnrestricted(context: Context): Boolean {
        val power = context.getSystemService(PowerManager::class.java)
        return power?.isIgnoringBatteryOptimizations(context.packageName) == true
    }

    // Opens the settings page for one permission. Returns false if nothing
    // could be opened at all.
    fun open(context: Context, name: String): Boolean {
        val pkgUri = Uri.parse("package:${context.packageName}")
        val intent = when (name) {
            // There's no reliable direct link to one app's switch, so we
            // open the Accessibility list; App Lock is in there.
            "accessibility" -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)

            "overlay" -> Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkgUri)

            "fingerprint" ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    // Android 11+: straight to "Add a fingerprint".
                    Intent(Settings.ACTION_BIOMETRIC_ENROLL).putExtra(
                        Settings.EXTRA_BIOMETRIC_AUTHENTICATORS_ALLOWED,
                        BiometricManager.Authenticators.BIOMETRIC_STRONG,
                    )
                } else {
                    Intent(Settings.ACTION_SECURITY_SETTINGS)
                }

            "battery" ->
                if (isBatteryUnrestricted(context)) appInfo(pkgUri) else batteryPopup(pkgUri)

            else -> appInfo(pkgUri) // "appInfo": App Lock's App info page
        }
        return start(context, intent) || start(context, appInfo(pkgUri))
    }

    // Android's popup: "Let app always run in background?" → Allow.
    // (Google limits this for Play Store apps; fine for a personal APK.)
    @SuppressLint("BatteryLife")
    private fun batteryPopup(pkgUri: Uri) =
        Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, pkgUri)

    // App info → here you find Battery, and "Allow restricted settings" (⋮).
    private fun appInfo(pkgUri: Uri) =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkgUri)

    private fun start(context: Context, intent: Intent): Boolean {
        // Opening a page from a non-Activity context needs a new task.
        if (context !is Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false // this phone doesn't have that page
        }
    }
}
