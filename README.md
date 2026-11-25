<p align="center">
  <img src="design/app_icon.png" width="120" alt="App Lock icon">
</p>

<h1 align="center">App Lock</h1>

<p align="center">
  Lock any Android app behind your fingerprint, with a backup PIN.<br>
  Built with Flutter and Kotlin.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Kotlin" src="https://img.shields.io/badge/Kotlin-Android-7F52FF?logo=kotlin&logoColor=white">
  <img alt="Android" src="https://img.shields.io/badge/Android-7.0%2B-3DDC84?logo=android&logoColor=white">
</p>

---

## What it does

You choose apps such as WhatsApp, Instagram or Photos. When one of them opens, App Lock
covers it with a lock screen and asks for your fingerprint. If the fingerprint doesn't
work, you can use your backup PIN instead.

I built it as a personal project for my Motorola Edge 40 Neo (Android 15, in-display
fingerprint sensor). It should work on most Android phones with a fingerprint sensor.
It is not on the Play Store. You install it as an APK.

## Screenshots

<table align="center">
  <tr><th align="center">Home</th><th align="center">Lock screen</th><th align="center">Backup PIN</th><th align="center">Settings</th></tr>
  <tr><td align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dark-home.png"><img src="docs/screenshots/light-home.png" width="175" alt="Home screen with locked and other apps"></picture></td><td align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dark-lock.png"><img src="docs/screenshots/light-lock.png" width="175" alt="Lock screen asking for a fingerprint"></picture></td><td align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dark-lock-pin.png"><img src="docs/screenshots/light-lock-pin.png" width="175" alt="PIN entry after a wrong PIN, 3 tries left"></picture></td><td align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dark-settings.png"><img src="docs/screenshots/light-settings.png" width="175" alt="Settings screen"></picture></td></tr>
</table>

<details>
<summary><b>First-time setup screens</b></summary>
<br>

<table align="center">
  <tr><th align="center">Welcome</th><th align="center">Create PIN</th><th align="center">Permissions</th></tr>
  <tr><td align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dark-welcome.png"><img src="docs/screenshots/light-welcome.png" width="200" alt="Welcome screen"></picture></td><td align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dark-set-pin.png"><img src="docs/screenshots/light-set-pin.png" width="200" alt="Create a backup PIN"></picture></td><td align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dark-permissions.png"><img src="docs/screenshots/light-permissions.png" width="200" alt="Permissions checklist"></picture></td></tr>
</table>

</details>

**Light and dark theme.** The app follows the phone's theme. The screenshots above follow
your GitHub theme.

<p align="center">
  <img src="docs/screenshots/light-lock.png" width="200" alt="Lock screen, light theme">
  &nbsp;&nbsp;
  <img src="docs/screenshots/dark-lock.png" width="200" alt="Lock screen, dark theme">
</p>

<sub>Screenshots use demo apps. They are drawn from the real screens by
<code>tool/screenshots/</code> (see <a href="#updating-the-screenshots">Updating the screenshots</a>).</sub>

## Features

- **Fingerprint unlock** using Android's own fingerprint popup.
- **Backup PIN** (4–6 digits). After 5 wrong tries you wait 30 seconds.
  "Forgot PIN?" lets you in with your phone's screen lock.
- **Pick apps to lock** from a searchable list of your installed apps, with one master switch.
- **Unlock animation**: after a correct fingerprint or PIN, a check mark pops in and the
  lock screen fades away into your app (skipped when "Remove animations" is on).
- **Fast lock screen**: the lock screen's Flutter engine starts in the background when the
  app starts, so the lock screen appears without a delay.
- **Re-lock timer**: lock again right away, after 1 minute or after 5 minutes of leaving an app.
- **Lock when the screen turns off**: every app is locked again when the screen goes off.
- **Calls are never blocked**: while the phone rings or a call is on, the call screen stays
  visible even if the Phone app is locked.
- **Lock Settings & Play Store**: stops someone from uninstalling App Lock or turning it off.
- **Hide previews in Recents**: App Lock's screens show as a blank card in Recent apps.
- **Health check** that shows whether every permission is still on, with a tap to fix each one.
- **Light and dark themes** that follow the phone's system setting.

## Privacy

- Nothing leaves the phone. The app has no internet permission and no analytics.
- **Your PIN is never stored.** Only a salted hash is kept: a random 16-byte salt, then
  SHA-256 repeated 10,000 times. It is saved in Android's encrypted storage
  (`flutter_secure_storage`).
- The app never sees your fingerprint. Android checks it and only tells App Lock whether
  it matched.
- The Accessibility service only reads **which app** you're using (its package name, for
  example `com.whatsapp`). To ask Android which window is active, the service needs
  `canRetrieveWindowContent="true"`, so Android's Accessibility page may describe it as able
  to view the screen. App Lock reads **only the package name**, never text or images.

## How it works

```
 You open WhatsApp
        │
        ▼
 LockAccessibilityService  ──  "a new app window opened: com.whatsapp"
        │   (also: "the active window changed", e.g. back from Recent apps)
        │   Is it locked? Was it unlocked recently?
        ▼
 Instant cover  (a plain overlay window, shown in one frame, hides the app)
        ▼
 LockActivity  (uses the pre-warmed FlutterEngine from FlutterEngineCache)
        │   Dart entry point lockMain() draws the lock screen
        ▼
 Fingerprint or PIN OK  →  the lock screen closes and WhatsApp is underneath
```

| Part | Language | Job |
|---|---|---|
| `LockAccessibilityService` | Kotlin | Watches which app comes to the front, covers it at once and starts the lock screen |
| `LockActivity` + `LockEngine` | Kotlin | Shows the lock screen with a cached, pre-warmed Flutter engine |
| `UnlockSession` | Kotlin | Remembers unlocked apps until the re-lock timer runs out or the screen turns off |
| `LockedAppsStore`, `SettingsStore` | Kotlin | Saves the locked apps and settings so the service can read them without Flutter |
| `NativeChannel` | Kotlin | MethodChannel `app_lock/native` between the Flutter screens and Android |
| `lib/screens/` | Dart | All screens: welcome, set PIN, permissions, home, lock, lock PIN, settings |
| `lib/services/` | Dart | PIN hashing, fingerprint (`local_auth`), settings, permission checks |

App Lock never locks itself, the home-screen app or the system UI.

## Project structure

```
lib/
  main.dart            App start; lockMain() is the lock screen's entry point
  routes.dart          Screen names and navigation
  screens/             The 7 screens
  lock/                Lock-screen app that runs in the pre-warmed engine
  services/            PIN, fingerprint, settings, permissions, native bridge
  theme/               Colors (light + dark) and fonts
  widgets/             Shared buttons, switches, keypad, app tiles
android/app/src/main/kotlin/com/krishna/applock/
                       Accessibility service, lock activity, storage, bridge
design/                Approved screen designs (HTML, dark + light) and the logo
docs/screenshots/      README screenshots
tool/screenshots/      Makes those screenshots from the real screens
test/                  Dart unit and widget tests
android/app/src/test/  Kotlin unit tests for UnlockSession
```

## Build and install

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) and the Android SDK
(Android Studio installs it).

```bash
git clone https://github.com/Krish1712204/App-Lock.git
cd App-Lock
flutter pub get

flutter run                      # run on a connected phone
flutter analyze                  # check the code
flutter test                     # run the Dart tests
flutter build apk --release      # build the APK
```

The APK is saved to `build/app/outputs/flutter-apk/app-release.apk`.

> The release build is signed with the local **debug key**, which is fine for a personal
> sideloaded app. To publish the app, set up your own signing key first.

### Updating the screenshots

The README screenshots are drawn from the real Flutter screens with demo data, in both
themes, so they never show anyone's real apps.

```bash
flutter test tool/screenshots/screenshots_test.dart --update-goldens   # raw 1170×2532 PNGs
python tool/screenshots/round_corners.py                              # rounded, into docs/screenshots/
```

The second step needs Pillow (`pip install pillow`).

## First-time setup on the phone

1. Install the APK and open **App Lock**.
2. Create your backup PIN.
3. Turn on the permissions the app asks for:
   - **Accessibility**: lets App Lock see which app opens.
   - **Display over other apps**: lets the lock screen open on top of other apps.
   - **Fingerprint**: a fingerprint must be saved in the phone's settings.
   - **Battery: Unrestricted**: stops Android from closing App Lock in the background.
4. Pick the apps to lock and turn on the master switch.

**Accessibility switch greyed out?** Android 13 and newer block this for apps that aren't
from the Play Store. Go to **Settings → Apps → App Lock → ⋮ (top right) → Allow restricted
settings**, then turn on Accessibility again.

**Lock stops working after a while?** Some phones close background apps to save battery.
Set App Lock's battery use to **Unrestricted**, and lock App Lock in Recent apps if your
phone allows it.

## Limitations

- Android only tells an app lock which app opened once that app's window is in front.
  When you reopen an app that is still in memory, you may see it for about 0.2 seconds
  during the opening animation before App Lock's cover hides it.
- Popups that float over another app without taking focus (for example Truecaller's
  after-call card) are treated like notifications and are not locked. Opening the app
  itself is locked.
- If someone turns off the Accessibility service, nothing gets locked. Turn on
  **Lock Settings & Play Store** to make that harder.
- Android only. There is no iOS version, because iOS doesn't let apps lock other apps.

## Tech stack

Flutter (Dart) · Kotlin · `local_auth` · `flutter_secure_storage` · `crypto` · `flutter_svg`

Fonts: [Inter](https://rsms.me/inter/) and [Space Grotesk](https://github.com/floriankarsten/space-grotesk),
both under the SIL Open Font License.
