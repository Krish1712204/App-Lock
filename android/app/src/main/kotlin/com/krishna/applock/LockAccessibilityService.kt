package com.krishna.applock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import android.widget.Toast

// The "watcher". Android tells it every time a new window comes to the
// front (TYPE_WINDOW_STATE_CHANGED). We read ONLY the package name of that
// window (e.g. "com.whatsapp") and check it against the locked list.
//
// It never reads screen content: the config file
// (res/xml/accessibility_service_config.xml) sets
// canRetrieveWindowContent="false", so Android doesn't even allow it.
//
// You turn this on in: Settings → Accessibility → App Lock.
class LockAccessibilityService : AccessibilityService() {

    // The app that was in front last time, so we react only when it changes.
    private var lastPackage: String? = null

    // Packages we must never lock: App Lock itself, the system UI
    // (status bar, notifications), the home screen app, and keyboards.
    private var ignored: Set<String> = emptySet()

    // Called once, when you turn the service on (or after a reboot).
    override fun onServiceConnected() {
        super.onServiceConnected()
        ignored = buildIgnoredList()
        Log.d(TAG, "Watcher started. Ignoring: $ignored")
    }

    // Called by Android for every event we asked for in the config file.
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        if (pkg in ignored) return // keyboard, status bar, launcher, ourselves
        if (pkg == lastPackage) return // same app is still in front
        lastPackage = pkg

        if (!LockedAppsStore.isProtectionOn(this)) return // master switch is off
        if (pkg in LockedAppsStore.getLocked(this)) {
            onLockedAppOpened(pkg)
        }
    }

    private fun onLockedAppOpened(pkg: String) {
        Log.d(TAG, "Locked app opened: $pkg")
        // PHASE 3 ONLY: a small message so you can see detection works.
        // Phase 4 replaces this with the real lock screen (LockActivity).
        Toast.makeText(this, "${appName(pkg)} is locked", Toast.LENGTH_SHORT).show()
    }

    // Required by Android; called if the system interrupts feedback.
    // We don't give feedback (no sounds or speech), so nothing to do.
    override fun onInterrupt() {}

    // The app's visible name, e.g. "WhatsApp". Falls back to the package name.
    private fun appName(pkg: String): String = try {
        val info = packageManager.getApplicationInfo(pkg, 0)
        packageManager.getApplicationLabel(info).toString()
    } catch (e: PackageManager.NameNotFoundException) {
        pkg
    }

    private fun buildIgnoredList(): Set<String> {
        val result = mutableSetOf(packageName, "com.android.systemui")

        // Home screen apps: ask Android which apps answer the "Home" intent.
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        @Suppress("DEPRECATION") // the newer overload needs Android 13+
        packageManager.queryIntentActivities(home, 0).forEach {
            result.add(it.activityInfo.packageName)
        }

        // Keyboards: their window pops up over the app you're typing in.
        val imm = getSystemService(InputMethodManager::class.java)
        imm?.enabledInputMethodList?.forEach { result.add(it.packageName) }

        return result
    }

    companion object {
        private const val TAG = "AppLockWatcher" // filter logcat with this
    }
}
