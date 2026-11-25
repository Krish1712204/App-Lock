package com.krishna.applock

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import io.flutter.embedding.android.FlutterFragmentActivity

// The lock screen that covers a locked app.
//
// It's a FlutterFragmentActivity (needed by local_auth) that borrows the
// pre-warmed engine from LockEngine instead of starting a new one, so it
// appears almost instantly.
//
// In AndroidManifest.xml it is:
//  - singleInstance + its own taskAffinity: it lives in its own "task", so
//    when it closes, the app underneath (e.g. WhatsApp) is shown again;
//  - excludeFromRecents: it never shows up in Recent apps.
class LockActivity : FlutterFragmentActivity() {

    companion object {
        private const val EXTRA_PACKAGE = "locked_package"

        // The lock screen that's open right now (null if none).
        // LockEngine uses it to close the lock when Dart says "unlocked".
        var current: LockActivity? = null
            private set

        // True from the moment the watcher asks for the lock until the lock
        // screen is really gone (closed, or hidden with the Home button).
        // The watcher uses it to tell "our lock screen is on top" apart from
        // "you opened App Lock". (Checking the window's class name isn't
        // enough: the lock window also sends events named
        // "android.widget.FrameLayout", which caused the lock loop.)
        val isShowing: Boolean
            // "Visible", or "asked for less than 2 s ago and still opening".
            // The 2 s limit means: if Android ever refused to open it, we
            // don't wrongly think it's showing forever.
            get() = visible || SystemClock.uptimeMillis() - requestedAt < 2_000

        @Volatile
        private var visible = false

        @Volatile
        private var requestedAt = 0L

        // Called by the watcher when a locked app comes to the front.
        fun start(context: Context, packageName: String) {
            requestedAt = SystemClock.uptimeMillis()
            val intent = Intent(context, LockActivity::class.java)
                .putExtra(EXTRA_PACKAGE, packageName)
                .addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or // required when starting from a service
                        Intent.FLAG_ACTIVITY_NO_ANIMATION or // appear at once, no slide-in
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
                )
            context.startActivity(intent)
        }
    }

    // Use the cached, pre-warmed engine instead of creating a new one.
    override fun getCachedEngineId(): String = LockEngine.ENGINE_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        // Make sure the engine exists (it normally already does), and tell
        // Dart which app to show BEFORE the screen is drawn. That way the
        // first frame already shows the right app.
        LockEngine.warmUp(this)
        intent.getStringExtra(EXTRA_PACKAGE)?.let { LockEngine.showLock(this, it) }
        super.onCreate(savedInstanceState)
        SecureScreen.apply(this) // "Hide previews in Recent apps"
        current = this
        skipAnimation(opening = true)
    }

    // The lock is already open (in the background) and another locked app
    // was opened: reuse this screen with the new app.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(EXTRA_PACKAGE)?.let { LockEngine.showLock(this, it) }
    }

    override fun onStart() {
        super.onStart()
        visible = true
    }

    // The lock is no longer visible (closed, or you pressed Home).
    // A screen rotation also stops/starts it; that doesn't count.
    override fun onStop() {
        if (!isChangingConfigurations) {
            visible = false
            requestedAt = 0L
        }
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        current = this
        LockEngine.notifyResumed(true)
        // The lock screen is now on top of the app: remove the watcher's
        // instant cover. Wait a moment, so the lock screen is surely drawn
        // first (its window background already matches the cover's color).
        window.decorView.postDelayed({ LockAccessibilityService.hideCover() }, 120)
    }

    override fun onPause() {
        LockEngine.notifyResumed(false)
        super.onPause()
    }

    override fun onDestroy() {
        if (current === this) {
            current = null
            visible = false
        }
        super.onDestroy()
    }

    // Unlock worked: close, so the locked app underneath is visible again.
    fun closeLock() {
        finish()
        skipAnimation(opening = false)
    }

    // Back was pressed: show the phone's home screen, then close.
    fun goHome() {
        val home = Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_HOME)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(home)
        finish()
    }

    // Turn off the open/close animation, so the lock appears and disappears
    // at once. Android 14+ has a new way: set both once, in onCreate.
    // Older versions use the old (now "deprecated") method right after
    // opening/closing.
    private fun skipAnimation(opening: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            if (opening) {
                overrideActivityTransition(OVERRIDE_TRANSITION_OPEN, 0, 0)
                overrideActivityTransition(OVERRIDE_TRANSITION_CLOSE, 0, 0)
            }
        } else {
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
    }
}
