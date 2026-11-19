package com.krishna.applock

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// The main screen of the app. All the UI is drawn by Flutter.
//
// Why FlutterFragmentActivity (and not FlutterActivity)?
// Android's fingerprint popup (BiometricPrompt) is built on "Fragments",
// so the local_auth package only works inside a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {

    // Called once when the Flutter engine is ready. We connect our
    // MethodChannel "app_lock/native" here, so Dart can talk to Kotlin.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine) // keeps the plugins working
        NativeChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
