package com.krishna.applock

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

// Builds the list of apps shown on the Home screen.
//
// We ask Android for every app that has an icon in the app drawer
// (an activity with ACTION_MAIN + CATEGORY_LAUNCHER). That skips hidden
// system parts that you can't open anyway.
object InstalledApps {
    private const val ICON_SIZE_PX = 120 // about 44dp on your phone's screen

    // Returns one map per app: name, packageName, icon (PNG bytes).
    // Flutter receives these as Dart Maps. This is slow-ish (it draws every
    // icon), so always call it on a background thread.
    fun load(context: Context): List<Map<String, Any>> {
        val pm = context.packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

        @Suppress("DEPRECATION") // the newer overload needs Android 13+
        val entries = pm.queryIntentActivities(launcherIntent, 0)

        return entries
            .distinctBy { it.activityInfo.packageName } // some apps have 2 icons
            .filter { it.activityInfo.packageName != context.packageName } // not App Lock itself
            .map { entry ->
                mapOf(
                    "packageName" to entry.activityInfo.packageName,
                    "name" to entry.loadLabel(pm).toString(),
                    "icon" to entry.loadIcon(pm).toPng(ICON_SIZE_PX),
                )
            }
    }

    // Draws an icon onto a square bitmap and saves it as PNG bytes.
    private fun Drawable.toPng(size: Int): ByteArray {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        setBounds(0, 0, size, size)
        draw(canvas)
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        bitmap.recycle() // free the memory now
        return out.toByteArray()
    }
}
