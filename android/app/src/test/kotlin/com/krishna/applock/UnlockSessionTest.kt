package com.krishna.applock

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

// Tests for the "Lock again after" timer. They pretend time passes by
// replacing UnlockSession's clock, so they run instantly.
class UnlockSessionTest {
    private var now = 0L // pretend time, in milliseconds
    private val oneMinute = 60_000L

    @Before
    fun setUp() {
        now = 1_000_000L
        UnlockSession.clock = { now }
        UnlockSession.relockAll()
    }

    @Test
    fun `an app you never unlocked is locked`() {
        assertFalse(UnlockSession.isUnlocked("com.whatsapp", oneMinute))
    }

    @Test
    fun `stays unlocked while you are inside it`() {
        UnlockSession.markInside("com.whatsapp")
        now += 10 * oneMinute
        assertTrue(UnlockSession.isUnlocked("com.whatsapp", 0))
    }

    @Test
    fun `right away locks as soon as you leave`() {
        UnlockSession.markInside("com.whatsapp")
        UnlockSession.left("com.whatsapp")
        assertFalse(UnlockSession.isUnlocked("com.whatsapp", 0))
    }

    @Test
    fun `1 min timer - back in 30 seconds stays unlocked, after 61 seconds locks`() {
        UnlockSession.markInside("com.whatsapp")
        UnlockSession.left("com.whatsapp")
        now += 30_000
        assertTrue(UnlockSession.isUnlocked("com.whatsapp", oneMinute))

        UnlockSession.left("com.whatsapp")
        now += 61_000
        assertFalse(UnlockSession.isUnlocked("com.whatsapp", oneMinute))
    }

    @Test
    fun `right away - a quick blip just after unlocking does not lock again`() {
        UnlockSession.markUnlocked("com.truecaller")
        now += 300 // the lock screen is closing
        UnlockSession.left("com.truecaller") // Android reports another window...
        now += 200
        assertTrue(UnlockSession.isUnlocked("com.truecaller", 0)) // ...no lock loop
    }

    @Test
    fun `right away - leaving after the grace time locks`() {
        UnlockSession.markUnlocked("com.whatsapp")
        now += UnlockSession.GRACE_MS + 5_000 // used it for a while
        UnlockSession.left("com.whatsapp")
        assertFalse(UnlockSession.isUnlocked("com.whatsapp", 0))
    }

    @Test
    fun `right away - leaving during grace locks once the grace time is over`() {
        UnlockSession.markUnlocked("com.whatsapp")
        UnlockSession.left("com.whatsapp")
        now += UnlockSession.GRACE_MS + 1
        assertFalse(UnlockSession.isUnlocked("com.whatsapp", 0))
    }

    @Test
    fun `screen off locks everything`() {
        UnlockSession.markInside("com.whatsapp")
        UnlockSession.relockAll()
        assertFalse(UnlockSession.isUnlocked("com.whatsapp", 5 * oneMinute))
    }
}
