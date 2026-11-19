package com.krishna.applock

// Remembers which locked apps you have already unlocked, so you aren't asked
// again every time the app shows a new screen.
//
// It lives only in memory: if Android closes App Lock's process, everything
// is locked again (the safe default).
//
// Phase 4: an app is locked again as soon as you leave it ("Right away"),
// and all apps are locked again when the screen turns off.
// Phase 6 adds the 1 min / 5 min timer and the on/off settings.
object UnlockSession {
    private val unlocked = mutableSetOf<String>()

    fun isUnlocked(packageName: String) = packageName in unlocked

    fun markUnlocked(packageName: String) {
        unlocked.add(packageName)
    }

    fun relock(packageName: String) {
        unlocked.remove(packageName)
    }

    fun relockAll() {
        unlocked.clear()
    }
}
