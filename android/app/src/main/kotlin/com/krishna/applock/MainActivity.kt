package com.krishna.applock

import io.flutter.embedding.android.FlutterFragmentActivity

// The main screen of the app. All the UI is drawn by Flutter.
//
// Why FlutterFragmentActivity (and not FlutterActivity)?
// Android's fingerprint popup (BiometricPrompt) is built on "Fragments",
// so the local_auth package only works inside a FragmentActivity.
class MainActivity : FlutterFragmentActivity()
