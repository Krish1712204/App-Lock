package com.krishna.applock

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// The lock screen's own Flutter engine, kept ready in FlutterEngineCache.
//
// A FlutterEngine is what runs Dart code and draws Flutter UI. Starting one
// takes about a second, which is too slow for a lock screen. So we start it
// once, early (see AppLockApplication), and LockActivity borrows it each time.
//
// This engine runs the Dart function `lockMain()` (in lib/main.dart),
// which shows only the lock UI, not the normal App Lock screens.
//
// It talks to Dart over its own channel, "app_lock/lock":
//   Kotlin → Dart:  showLock {app}, resumed, paused
//   Dart → Kotlin:  currentLock, unlocked {packageName}, goHome
object LockEngine {
    const val ENGINE_ID = "lock_engine"
    private const val CHANNEL = "app_lock/lock"

    private var channel: MethodChannel? = null

    // The app that is being locked right now: {packageName, name, icon}.
    // Kept here too, in case Dart asks for it ("currentLock") after starting.
    private var currentLock: Map<String, Any>? = null

    // Creates the engine once; later calls just return the same one.
    fun warmUp(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }

        val appContext = context.applicationContext
        // This also registers all plugins (local_auth, secure storage...).
        val engine = FlutterEngine(appContext)
        val bundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(bundlePath, "lockMain"),
        )

        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result -> onDartCall(call, result) }
        }
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }

    // Tells Dart which app to show on the lock screen, and whether to use
    // the fingerprint (Settings → Fingerprint unlock) or go straight to PIN.
    fun showLock(context: Context, packageName: String) {
        currentLock = InstalledApps.loadOne(context, packageName) +
            ("fingerprint" to SettingsStore.isOn(context, SettingsStore.FINGERPRINT))
        channel?.invokeMethod("showLock", currentLock)
    }

    // Tells Dart when LockActivity is on screen. The fingerprint popup can
    // only open while it is (Android needs a visible activity for it).
    fun notifyResumed(resumed: Boolean) {
        channel?.invokeMethod(if (resumed) "resumed" else "paused", null)
    }

    private fun onDartCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "currentLock" -> result.success(currentLock)

            "unlocked" -> {
                // Fingerprint or PIN was correct: remember it and close the lock.
                call.argument<String>("packageName")?.let { UnlockSession.markUnlocked(it) }
                currentLock = null
                LockActivity.current?.closeLock()
                result.success(null)
            }

            "goHome" -> {
                // Back was pressed on the lock screen: go to the home screen,
                // never into the locked app.
                currentLock = null
                LockActivity.current?.goHome()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
