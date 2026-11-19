# App Lock — project guide for Claude Code

## What this app is
A personal app lock for a Motorola Edge 40 Neo (Android 14/15, in-display fingerprint sensor).
The user picks apps (WhatsApp, Gallery, etc.). When a locked app opens, App Lock covers it with
a lock screen and asks for a fingerprint, with a backup PIN.
For personal use only. Installed as an APK, not published on the Play Store.

## Tech stack
- Flutter (Dart) for all screens.
- Kotlin (android/app/src/main/kotlin/...) for the background parts Flutter can't do:
  - `LockAccessibilityService`: listens for TYPE_WINDOW_STATE_CHANGED and reads the package name.
  - Starts `LockActivity` when a locked app comes to the front.
  - Saves the locked-app list in native SharedPreferences, so the service can read it without Flutter.
- Bridge: MethodChannel `app_lock/native`.
- Packages: `local_auth`, `flutter_secure_storage`, `installed_apps`, `permission_handler`, `shared_preferences`.

## Important rules
- `MainActivity` and `LockActivity` must extend `FlutterFragmentActivity`, or `local_auth` won't work.
- The lock screen must open fast: pre-warm a FlutterEngine at app start, keep it in `FlutterEngineCache`,
  and have `LockActivity` use the cached engine with a separate Dart entrypoint/route for the lock UI.
- Never store the PIN itself. Store a salted hash (SHA-256 + random salt) in `flutter_secure_storage`.
- Don't lock App Lock itself, the launcher, or the system UI (`com.android.systemui`).
- After a successful unlock, remember the package as "unlocked" until:
  the screen turns off (if that setting is on), or the re-lock timer runs out after leaving the app.
- The accessibility service only reads package names, never screen content.
- Keep the code simple and well-commented. The developer is learning.

## Screens (designs in /design)
The `design/dark` and `design/light` folders hold the approved screens as HTML. Read them for exact
layout, text, colors, sizes and corner radius. Build both themes and follow the phone's system theme.

1. Main.html: Welcome
2. SetPin.html: Create backup PIN (4–6 digits, keypad)
3. Permissions.html: Accessibility, Display over other apps, Fingerprint, Battery Unrestricted
4. Home.html: master switch, search, Locked / Other apps lists with switches
5. LockScreen.html: locked app icon + fingerprint prompt + "Use PIN instead"
6. LockPin.html: PIN entry, wrong-PIN state ("3 tries left"), fingerprint key
7. Settings.html: change PIN, fingerprint on/off, re-lock timer, lock on screen off, lock Settings & Play Store, hide Recents preview

## Design tokens
Fonts: Space Grotesk (headings, keypad numbers), Inter (body). Use the `google_fonts` package.
Corner radius: cards 16–22, buttons 28 (pill), app icons 14, keypad keys 20 (round on lock PIN).

| Token | Dark | Light |
|---|---|---|
| background | #0D1014 | #F6F7F9 |
| surface (cards) | #161A20 | #FFFFFF |
| surface2 (icon tiles) | #1E232B | #EEF1F4 |
| border | #232831 | #E3E7EC |
| text | #EEF1F5 | #12161C |
| muted text | #9AA3AF | #5B6573 |
| accent | #5EEAD4 | #0F766E |
| on-accent text | #0D1014 | #FFFFFF |
| error | #FF8A8A | #C42B2B |
| switch off track | #2A303A | #CBD2DB |

## Commands
- Run on phone: `flutter run`
- Analyze: `flutter analyze`
- Tests: `flutter test`
- Release APK: `flutter build apk --release` → build/app/outputs/flutter-apk/app-release.apk

## How we work
- Build one phase at a time. Make a plan first, then code.
- After each phase: run `flutter analyze`, fix problems, and tell me how to test it on the phone.
- Make a git commit after each phase that works.
