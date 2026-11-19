package com.krishna.applock

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
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

    // True for `flutter run` / debug APKs: then we log every event (for
    // fixing bugs). Release APKs stay quiet.
    private val isDebugBuild by lazy {
        (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
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
        UnlockSession.endHandOff() // start clean
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
        val cls = event.className?.toString()
        if (isDebugBuild) Log.v(TAG, "event pkg=$pkg class=$cls fg=$foregroundPackage")

        // A popup over the current app (keyboard, notifications...):
        // you haven't left the app.
        if (pkg in overlayPackages) return

        if (pkg == packageName) {
            // App Lock itself (never locked). Only its main screen counts as
            // "you switched to App Lock". Everything else is our lock window
            // covering an app (it also sends "android.widget.FrameLayout"
            // events, which once caused a lock loop).
            if (LockActivity.isShowing || cls != MainActivity::class.java.name) return
        } else if (pkg !in launcherPackages && !isRealScreen(pkg, cls)) {
            // Not a real app screen (an Activity) but a floating layer: Edge
            // lights, a toast, a bubble, a view inside a window... Those
            // must not count as "you left the app" (with "Right away" that
            // re-locked the app you had just unlocked).
            // The home screen is the exception: any event from it counts.
            return
        }

        // Still the same app in front (it just opened another screen).
        if (pkg == foregroundPackage) return

        // A different app is now in front, so you left the previous one.
        val previous = foregroundPackage
        foregroundPackage = pkg
        onLeft(previous)

        if (pkg in launcherPackages) return // home screen / Recent apps: never locked
        lockIfNeeded(pkg)
    }

    // Remembered answers of isRealScreen(), so we ask Android only once
    // per screen. ("package/class" → true/false)
    private val realScreenCache = HashMap<String, Boolean>()

    // Is this window a real app screen (an Activity listed in that app)?
    // Floating layers report a View class here, e.g. "android.widget.FrameLayout".
    private fun isRealScreen(pkg: String, cls: String?): Boolean {
        if (cls.isNullOrEmpty()) return false
        if (realScreenCache.size > 500) realScreenCache.clear() // keep memory small
        return realScreenCache.getOrPut("$pkg/$cls") {
            try {
                packageManager.getActivityInfo(ComponentName(pkg, cls), 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false // not an Activity (or an app we can't see)
            }
        }
    }

    // You left [previous]: start its relock timer. If it was a settings page
    // App Lock opened for you ("hand-off"), that free visit is now over.
    private fun onLeft(previous: String?) {
        if (previous == null) return
        UnlockSession.left(previous)
        if (previous == UnlockSession.handOff) UnlockSession.endHandOff()
    }

    // Should this app be covered by the lock screen at all?
    private fun isLockTarget(pkg: String): Boolean {
        if (pkg == packageName) return false // App Lock itself is never locked
        if (!LockedAppsStore.isProtectionOn(this)) return false // master switch is off
        if (pkg in LockedAppsStore.getLocked(this)) return true // you locked it on Home
        // "Lock Settings & Play Store" (+ the uninstall dialog).
        return SettingsStore.isOn(this, SettingsStore.LOCK_SYSTEM_APPS) && pkg in SYSTEM_APPS
    }

    // Shows the lock screen if this app is locked and not unlocked (in time).
    private fun lockIfNeeded(pkg: String) {
        if (!isLockTarget(pkg)) return
        if (UnlockSession.isUnlocked(pkg, SettingsStore.relockDelayMs(this))) {
            UnlockSession.markInside(pkg) // came back in time: no lock
            return
        }
        Log.d(TAG, "Locking $pkg")
        LockActivity.start(this, pkg)
    }

    // Screen turned off. If "Lock when screen turns off" is on, every app
    // needs a new check. If you were inside a locked app, put the lock on top
    // now, so it's already there when you turn the screen back on.
    private fun onScreenOff() {
        if (!SettingsStore.isOn(this, SettingsStore.LOCK_ON_SCREEN_OFF)) return
        UnlockSession.relockAll()
        foregroundPackage?.let { if (it !in launcherPackages) lockIfNeeded(it) }
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
            // Photo picker and file picker: an app opens them to let you
            // choose a file, then you're back in the same app.
            "com.google.android.providers.media.module",
            "com.android.providers.media.module",
            "com.google.android.documentsui",
            "com.android.documentsui",
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
            // Android Settings has a hidden emergency "home" screen
            // (FallbackHome), so it answers this question too. It's not a
            // real launcher, and it must stay lockable.
            .filter { it != "com.android.settings" }
            .toSet()
    }

    companion object {
        private const val TAG = "AppLockWatcher" // filter logcat with this

        // Locked when "Lock Settings & Play Store" is on. The package
        // installer shows the "Uninstall?" dialog, so it's here too.
        private val SYSTEM_APPS = setOf(
            "com.android.settings",
            "com.android.vending", // Play Store
            "com.google.android.packageinstaller",
            "com.android.packageinstaller",
        )

        // True while the watcher is connected and working. Read by the
        // Health check. (@Volatile: safe to read from any thread.)
        @Volatile
        var isRunning = false
            private set
    }
}
