package com.krishna.applock

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager

// The "watcher". Android tells it every time a new window comes to the
// front (TYPE_WINDOW_STATE_CHANGED). We read ONLY the package name of that
// window (e.g. "com.whatsapp") and the window's class name (to recognise
// our own lock screen). Nothing else.
//
// It never reads screen content: the config file
// (res/xml/accessibility_service_config.xml) sets
// canRetrieveWindowContent="false", so Android doesn't even allow it.
//
// You turn this on in: Settings → Accessibility → App Lock.
class LockAccessibilityService : AccessibilityService() {

    // The app you're using right now (the last "real" app in front).
    private var foregroundPackage: String? = null

    // Windows that pop up OVER an app without you leaving it:
    // status bar / notifications, keyboards, share sheets, permission popups.
    // They don't count as "leaving the app", and they're never locked.
    private var overlayPackages: Set<String> = emptySet()

    // Home screen apps (they also show Recent apps on most phones).
    // Going there DOES count as leaving the app, but they're never locked.
    private var launcherPackages: Set<String> = emptySet()

    // Gets told by Android when the screen turns off.
    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_SCREEN_OFF) onScreenOff()
        }
    }

    // Called once, when you turn the service on (or after a reboot).
    override fun onServiceConnected() {
        super.onServiceConnected()
        overlayPackages = findOverlayPackages()
        launcherPackages = findLauncherPackages()
        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // NOT_EXPORTED: only the system can send us this, not other apps.
            registerReceiver(screenOffReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenOffReceiver, filter)
        }
        LockEngine.warmUp(this) // normally already warm (AppLockApplication)
        isRunning = true
        Log.d(TAG, "Watcher started. Overlays: $overlayPackages, launchers: $launcherPackages")
    }

    override fun onDestroy() {
        isRunning = false
        // If the service stopped before it fully started, the receiver was
        // never registered, and unregistering would crash. So ignore that.
        try {
            unregisterReceiver(screenOffReceiver)
        } catch (e: IllegalArgumentException) {
            // wasn't registered
        }
        super.onDestroy()
    }

    // Called by Android for every event we asked for in the config file.
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // Our own lock screen covering an app: you haven't left that app.
        if (pkg == packageName && event.className == LockActivity::class.java.name) return
        // A popup over the current app (keyboard, notifications...): same.
        if (pkg in overlayPackages) return
        // Still the same app in front (it just opened another screen).
        if (pkg == foregroundPackage) return

        // A different app is now in front, so you left the previous one:
        // lock it again. ("Right away" for now; Phase 6 adds the timer.)
        foregroundPackage?.let { UnlockSession.relock(it) }
        foregroundPackage = pkg

        if (pkg in launcherPackages) return // home screen / Recent apps
        if (pkg == packageName) return // App Lock's own normal screens
        lockIfNeeded(pkg)
    }

    // Shows the lock screen if this app is locked and not unlocked yet.
    private fun lockIfNeeded(pkg: String) {
        if (!LockedAppsStore.isProtectionOn(this)) return // master switch is off
        if (pkg !in LockedAppsStore.getLocked(this)) return // not a locked app
        if (UnlockSession.isUnlocked(pkg)) return // you already unlocked it
        Log.d(TAG, "Locking $pkg")
        LockActivity.start(this, pkg)
    }

    // Screen turned off: every app needs a new check. If you were inside a
    // locked app, put the lock on top now, so it's already there when you
    // turn the screen back on (instead of the app flashing first).
    private fun onScreenOff() {
        UnlockSession.relockAll()
        foregroundPackage?.let { lockIfNeeded(it) }
    }

    // Required by Android; called if the system interrupts feedback.
    // We don't give feedback (no sounds or speech), so nothing to do.
    override fun onInterrupt() {}

    private fun findOverlayPackages(): Set<String> {
        val result = mutableSetOf(
            "com.android.systemui", // status bar, notifications, fingerprint popup
            "android", // system dialogs, "Open with" choosers
            "com.android.intentresolver", // share sheet (Android 14+)
            "com.google.android.permissioncontroller", // "Allow access to photos?"
            "com.android.permissioncontroller",
        )
        // Keyboards: their window pops up over the app you're typing in.
        val imm = getSystemService(InputMethodManager::class.java)
        imm?.enabledInputMethodList?.forEach { result.add(it.packageName) }
        return result
    }

    private fun findLauncherPackages(): Set<String> {
        // Ask Android which apps answer the "Home" button.
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        @Suppress("DEPRECATION") // the newer overload needs Android 13+
        return packageManager.queryIntentActivities(home, 0)
            .map { it.activityInfo.packageName }
            .toSet()
    }

    companion object {
        private const val TAG = "AppLockWatcher" // filter logcat with this

        // True while the watcher is connected and working. Read by the
        // Health check. (@Volatile: safe to read from any thread.)
        @Volatile
        var isRunning = false
            private set
    }
}
