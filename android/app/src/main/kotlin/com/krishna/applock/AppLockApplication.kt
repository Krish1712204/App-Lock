package com.krishna.applock

import android.app.Application

// Android creates this object first, every time App Lock's process starts:
// when you open App Lock, and also when Android starts the watcher
// (after a reboot, or after the process was closed to free memory).
//
// We use that moment to "pre-warm" the lock screen's Flutter engine, so it's
// already running when a locked app opens. Without this, the first lock
// would take about a second to appear.
class AppLockApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        LockEngine.warmUp(this)
    }
}
