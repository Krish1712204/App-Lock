package com.krishna.applock

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.telecom.TelecomManager
import android.util.Log
import android.view.View
import android.view.WindowManager
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
        instance = this
        isRunning = true
        Log.d(TAG, "Watcher started. Overlays: $overlayPackages, launchers: $launcherPackages")
    }

    override fun onDestroy() {
        isRunning = false
        removeCover()
        if (instance === this) instance = null
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
        if (event == null) return
        when (event.eventType) {
            // A new screen or popup opened.
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val pkg = event.packageName?.toString() ?: return
                val cls = event.className?.toString()
                if (isDebugBuild) Log.v(TAG, "screen: $pkg / $cls (fg=$foregroundPackage)")

                // Keyboard, notifications, fingerprint popup...: over the app.
                if (pkg in overlayPackages) return

                // FAST PATH: a real app screen (or its popup). Act at once,
                // this is the earliest moment Android tells us.
                if (isAppScreen(pkg, cls)) {
                    if (isFloatingOverAnotherApp(pkg)) {
                        Log.d(TAG, "Floating popup of $pkg: treated like a notification")
                        return
                    }
                    lastScreenPackage = pkg
                    lastScreenAt = SystemClock.uptimeMillis()
                    onAppInFront(pkg, how = "screen")
                    return
                }

                // Not a full screen. If it's a LOCKED app's window, it's
                // usually the splash Android shows while that app starts
                // (~0.2 s before the app's content). Hide it already.
                preCoverIfLocked(pkg)
                // Otherwise it's a floating layer (Edge lights, a bubble...)
                // or our own lock window. Ask which window you're using.
            }
            // Windows changed. We only care when the window you're USING
            // changed (e.g. you came back from Recent apps, which sends no
            // other event). Older Androids don't say what changed: check anyway.
            AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    val useful = AccessibilityEvent.WINDOWS_CHANGE_ACTIVE or
                        AccessibilityEvent.WINDOWS_CHANGE_FOCUSED
                    if (event.windowChanges and useful == 0) return
                }
            }
            else -> return
        }

        // The app of the window you're using right now. Floating layers
        // (Edge lights, bubbles, a starting splash) are never "the window
        // you're using", so they can't fool this.
        val active = activeWindowPackage() ?: return
        if (active != foregroundPackage && !trustActiveWindow(active)) {
            if (isDebugBuild) Log.v(TAG, "ignored active window $active (fg just showed a screen)")
            return
        }
        onAppInFront(active, how = "active window")
    }

    // When was the last real app screen shown, and by which app?
    private var lastScreenPackage: String? = null
    private var lastScreenAt = 0L

    // Should we believe "the active window is [active]"?
    // Usually yes. But some apps show a real screen that floats WITHOUT
    // taking focus (e.g. Truecaller's after-call popup over the home
    // screen). Then the active window says "home screen" while Truecaller
    // is clearly in front. Believing that made a lock loop: "left Truecaller"
    // → "Truecaller again" → lock → unlock → "left" → lock...
    private fun trustActiveWindow(active: String): Boolean {
        // A locked app you're using: always act at once (safety first).
        // This is how coming back from Recent apps gets locked.
        if (isLockTarget(active)) return true
        // Anything else may only say "you left the app" if that app hasn't
        // just shown a screen itself.
        val justShown = lastScreenPackage == foregroundPackage &&
            SystemClock.uptimeMillis() - lastScreenAt < 1_500
        return !justShown
    }

    // Is [pkg]'s new screen a popup that floats over ANOTHER app without
    // taking focus? Example: Truecaller's after-call card over Instagram or
    // the home screen. You can keep using the app underneath, so it's like
    // a notification: not locked, and you haven't left the app underneath.
    // (Locking it made a loop: Truecaller locked, then Instagram, then
    // Truecaller... because both looked "in front".)
    // Opening the app itself still locks: then its window takes focus.
    private fun isFloatingOverAnotherApp(pkg: String): Boolean {
        if (pkg in launcherPackages || pkg == packageName) return false
        val active = activeWindowPackage() ?: return false
        return active != pkg && active !in overlayPackages && active != packageName
    }

    // Is this event a real app screen we can trust right away?
    private fun isAppScreen(pkg: String, cls: String?): Boolean = when (pkg) {
        in launcherPackages -> true // home screen / Recent apps: always counts
        // App Lock: only its main screen means "you opened App Lock". Its
        // lock window also sends events (e.g. "android.widget.FrameLayout").
        packageName -> cls == MainActivity::class.java.name
        // Other apps: an Activity, or a popup that belongs to one.
        else -> isRealScreen(pkg, cls) || isDialog(cls)
    }

    // A locked app is starting (its splash screen appeared): cover it now,
    // before its content can show. If it turns out to be something else
    // (e.g. a floating window of that app), the cover goes away after 0.8 s.
    private fun preCoverIfLocked(pkg: String) {
        if (pkg == foregroundPackage || !isLockTarget(pkg)) return
        if (UnlockSession.isUnlocked(pkg, SettingsStore.relockDelayMs(this))) return
        showCover(timeoutMs = 800)
    }

    // The package name of the window you're using, e.g. "com.whatsapp".
    // We read ONLY the package name, nothing that's on the screen.
    private fun activeWindowPackage(): String? {
        val root = try {
            rootInActiveWindow
        } catch (e: RuntimeException) {
            null // the window went away while we asked
        } ?: return null
        val pkg = root.packageName?.toString()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            @Suppress("DEPRECATION") // needed before Android 13, automatic after
            root.recycle()
        }
        return pkg
    }

    // [pkg] is the app in front now. Decide if you left the previous app
    // and if [pkg] must be locked.
    private fun onAppInFront(pkg: String, how: String) {
        // A popup over the current app (keyboard, notifications, fingerprint
        // popup...): you haven't left the app.
        if (pkg in overlayPackages) return

        // Our own lock window covering an app: nothing changed.
        if (pkg == packageName && LockActivity.isShowing) return

        // The call screen during a call: like a popup over what you were
        // doing. Never locked, and you haven't "left" your app.
        if (isCallScreen(pkg)) return

        // Still the same app in front (it just opened another screen).
        if (pkg == foregroundPackage) return
        // Logged in release builds too (package names only), to find bugs.
        Log.d(TAG, "In front: $pkg (from $how)")

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

    // Is this window a popup (Dialog)? A Dialog always belongs to an app
    // screen that is open right now, so it means "this app is in front".
    // Example: Google Photos sometimes opens with a popup first, and its
    // own screen sends no event. Without this, Photos opened unlocked.
    // (Class names like "android.app.Dialog", "...AlertDialog",
    // "...BottomSheetDialog".)
    private fun isDialog(cls: String?): Boolean =
        cls != null && cls.substringAfterLast('.').contains("Dialog")

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
        if (isCallScreen(pkg)) return false // never hide a ringing/active call
        if (!LockedAppsStore.isProtectionOn(this)) return false // master switch is off
        if (pkg in LockedAppsStore.getLocked(this)) return true // you locked it on Home
        // "Lock Settings & Play Store" (+ the uninstall dialog).
        return SettingsStore.isOn(this, SettingsStore.LOCK_SYSTEM_APPS) && pkg in SYSTEM_APPS
    }

    // Is [pkg] the phone app while a call is ringing or going on?
    // Then it's the call screen, and you must be able to answer or hang up
    // without unlocking. (After the call, the phone app is locked again:
    // call history, contacts...)
    // Neither check needs a permission:
    //  - TelecomManager names the default phone app,
    //  - AudioManager's mode is "normal" unless a call rings or is active.
    private fun isCallScreen(pkg: String): Boolean {
        val dialer = getSystemService(TelecomManager::class.java)?.defaultDialerPackage
        if (pkg != dialer) return false
        val mode = getSystemService(AudioManager::class.java)?.mode ?: return false
        return mode != AudioManager.MODE_NORMAL
    }

    // Shows the lock screen if this app is locked and not unlocked (in time).
    private fun lockIfNeeded(pkg: String) {
        if (!isLockTarget(pkg)) return
        if (UnlockSession.isUnlocked(pkg, SettingsStore.relockDelayMs(this))) {
            UnlockSession.markInside(pkg) // came back in time: no lock
            return
        }
        Log.d(TAG, "Locking $pkg")
        showCover(timeoutMs = 2_500) // hide the app now; the lock screen takes ~0.3 s
        LockActivity.start(this, pkg)
    }

    // ---- Instant cover ----
    // A plain full-screen window in App Lock's background color. An
    // Accessibility service may show one without any extra permission, and
    // it appears in one frame (~16 ms), much faster than starting the lock
    // screen. LockActivity removes it as soon as the lock screen is visible
    // (hideCover). Safety net: it removes itself after 2.5 s anyway, so it
    // can never get stuck over your phone.

    private var cover: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private val coverTimeout = Runnable { removeCover() }

    // Shows the cover (if not already shown) and removes it after
    // [timeoutMs] at the latest.
    private fun showCover(timeoutMs: Long) {
        handler.removeCallbacks(coverTimeout)
        handler.postDelayed(coverTimeout, timeoutMs)
        if (cover != null) return
        val view = View(this).apply {
            // values/colors.xml or values-night/colors.xml: follows dark mode.
            setBackgroundColor(getColor(R.color.app_background))
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            // Doesn't take keyboard focus, and covers the status bar area too.
            // It does catch touches, so nothing in the locked app can be tapped.
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.OPAQUE,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // Also draw under the camera cut-out.
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        try {
            getSystemService(WindowManager::class.java).addView(view, params)
            cover = view
        } catch (e: RuntimeException) {
            Log.w(TAG, "Couldn't show the cover", e) // the lock screen still opens
        }
    }

    private fun removeCover() {
        handler.removeCallbacks(coverTimeout)
        val view = cover ?: return
        cover = null
        try {
            getSystemService(WindowManager::class.java).removeView(view)
        } catch (e: RuntimeException) {
            // already gone
        }
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

        // The running watcher, so LockActivity can remove the cover.
        private var instance: LockAccessibilityService? = null

        // Called by LockActivity once the lock screen is visible.
        // (Main thread only, like the watcher itself.)
        fun hideCover() {
            instance?.removeCover()
        }
    }
}
