# Manual Android updates for Clinic System

The app checks Firebase Remote Config once per Android app session after Firebase starts. It downloads the APK from the `apk_url` HTTPS Firebase Storage link with Android Download Manager, then opens Android's installer. No Firebase Admin credential, CI job, app store, or Storage rule change is needed.

## Before the first update

- The Android application ID is `com.example.rmc_clinic_health`. Keep it unchanged for every update.
- The currently installed staff APKs use the **debug signing key**. This project's release build also currently uses that debug key. To install over those APKs without removing app data, build on the machine with the **same** `~/.android/debug.keystore` (on Windows, `%USERPROFILE%\.android\debug.keystore`). Back up that keystore securely. A new release key cannot update the existing installations directly.
- A production release key is preferable for a fresh deployment, but changing to it would require a migration or reinstall of the debug-signed copies. Do not change the signing configuration in the middle of this update series.
- Firebase's Spark plan blocks `.apk` uploads to Cloud Storage. The bucket must be on a plan that permits APK hosting.

## Prepare and upload a release

1. Increase `version:` in `pubspec.yaml`, for example from `1.0.0+1` to `1.1.0+2`. The number after `+` must exceed the installed build number.
2. Run `flutter pub get`, then `flutter build apk --release` in the project root. The APK is `build/app/outputs/flutter-apk/app-release.apk`.
3. Check that the APK has the same application ID and signing certificate as the installed APK. Android refuses an in-place update if the certificate differs. The Android SDK `apksigner verify --print-certs` command shows an APK certificate fingerprint.
4. In Firebase Console → Storage, upload the APK to a versioned name such as `clinic_updates/clinic-system-v1.1.0.apk`. Set the content type to `application/vnd.android.package-archive` if the console does not detect it.
5. Copy the file's **download URL** from Storage. It should start with `https://firebasestorage.googleapis.com/`. Do not use a `gs://` URL or the Firebase Console page URL. Anyone holding a token download URL may be able to retrieve the APK, so share it only as needed and rotate the token if it leaks.
6. In Firebase Console → Remote Config, create or update these parameters, then **Publish changes**:

   | Parameter | Example value | Meaning |
   | --- | --- | --- |
   | `latest_version` | `1.1.0` | Version shown to staff |
   | `latest_build` | `2` | New APK build number |
   | `minimum_build` | `1` | Builds below this must update |
   | `force_update` | `false` | Set `true` to require the update for older builds |
   | `apk_url` | Firebase Storage download URL | Exact APK to download |
   | `release_notes` | `Improved patient search\nFixed ticket issues` | Newline separated notes |

Publish the APK and confirm its URL works **before** raising `minimum_build` or setting `force_update=true`. A required update with a missing or invalid URL blocks the app and shows an administrator error.

## Test the flow

1. Keep an older build (for example `1.0.0+1`) installed on an Android test device. Do not uninstall it. Confirm its signing certificate matches the new APK.
2. For an optional update, publish `latest_build=2`, `minimum_build=1`, `force_update=false`, and a working `apk_url`. Fully close and reopen the old app. Check **Later** opens the normal app. Reopen it, tap **Update Now**, and let Android download and install the APK.
3. For a forced update, reinstall or keep the old build, publish `force_update=true` or `minimum_build=2`, then reopen it. Confirm there is no **Later** button and back/outside taps do not dismiss the dialog. Complete the update.
4. On the first install attempt, Android may open **Install unknown apps** settings. Allow installs from Clinic System, return to the app, then confirm the Android installer. This is a device-level permission; the app cannot approve it automatically.
5. After installation, confirm the app reports the new version and its existing patient data/session remain available. If Android says the app cannot be installed, compare the package ID, signing certificate, and build number.

Remote Config uses the existing app's fetch interval (currently one minute). If a just-published value has not appeared, wait at least a minute and fully reopen the app. When offline, the app uses the last activated Remote Config values; on a device that has never received a required update setting, the app cannot know about that new requirement until it connects.

## Android configuration

`AndroidManifest.xml` declares `INTERNET` and `REQUEST_INSTALL_PACKAGES`. The APK is downloaded into the app's external files directory, so no storage permission is needed. Android itself asks the user to approve installation. No Firebase Storage rules or Firestore/Auth rules are changed by this feature.
