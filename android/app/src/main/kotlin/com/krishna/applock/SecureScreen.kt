package com.krishna.applock

import android.app.Activity
import android.view.WindowManager

// "Hide previews in Recent apps".
//
// FLAG_SECURE tells Android: don't show this window's content in Recent
// apps, screenshots or screen recordings. Android only lets an app set it
// on ITS OWN windows, so this protects App Lock's screens (lock screen,
// PIN pad, app list), not WhatsApp's own Recents card.
object SecureScreen {
    fun apply(activity: Activity) {
        if (SettingsStore.isOn(activity, SettingsStore.HIDE_RECENTS)) {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
