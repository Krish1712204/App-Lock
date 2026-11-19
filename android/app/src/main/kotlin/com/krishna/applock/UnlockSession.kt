package com.krishna.applock

import android.os.SystemClock

// Remembers which locked apps you have unlocked, and for how long.
//
// For each unlocked app we keep ONE value:
//  - null      → you're inside the app right now: it stays unlocked;
//  - a number  → the time you left it. It stays unlocked until the
//                "Lock again after" delay (0 s / 1 min / 5 min) has passed.
//
// The time comes from SystemClock.elapsedRealtime(): time since the phone
// started. Changing the clock in Settings can't trick it.
//
// Everything is in memory only: if Android closes App Lock's process, all
// apps are locked again (the safe default).
object UnlockSession {
    // Replaceable "clock", so tests can pretend time passes.
    var clock: () -> Long = { SystemClock.elapsedRealtime() }

    private val unlocked = mutableMapOf<String, Long?>()

    // A settings page that App Lock itself just opened for you (for example
    // to fix a permission). Going there doesn't count as leaving App Lock,
    // and the page itself isn't locked.
    var handOff: String? = null
        private set

    // Is this app still unlocked, given the relock delay?
    fun isUnlocked(packageName: String, relockDelayMs: Long): Boolean {
        if (!unlocked.containsKey(packageName)) return false
        val leftAt = unlocked[packageName] ?: return true // still inside
        if (clock() - leftAt < relockDelayMs) return true // came back in time
        unlocked.remove(packageName) // too late: locked again
        return false
    }

    // You unlocked it, or came back to it in time: you're inside now.
    fun markInside(packageName: String) {
        unlocked[packageName] = null
    }

    // You left the app: start its relock timer.
    fun left(packageName: String) {
        if (unlocked.containsKey(packageName)) unlocked[packageName] = clock()
    }

    // App Lock is about to open [target] (e.g. Android Settings) for you.
    fun startHandOff(target: String) {
        handOff = target
        unlocked[target] = null
    }

    fun endHandOff() {
        handOff = null
    }

    // Screen turned off (and that setting is on): lock everything again.
    fun relockAll() {
        unlocked.clear()
        handOff = null
    }
}
