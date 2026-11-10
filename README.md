# Cloud Courier

A Flutter Android app for **CSC 4360 · In-Class Activity 14**. A Firebase Cloud
Messaging (FCM) notification with custom data changes the campus announcement
and switches between two bundled images. The screen shows the handler, message
ID, and event count for the current launch.

## 1. Connect your Firebase project

Use a recent stable Flutter SDK and Android Studio. Choose a physical Android
device with Google Play services or an Android emulator using a **Google Play**
system image. Android 13 or newer lets you capture the runtime notification
permission behavior.

1. Extract the ZIP and open a terminal in the `cloud_courier` folder, beside
   `pubspec.yaml`. Run `flutter doctor` and `flutter devices`.
2. Create or select a Firebase project you control. The Android application ID is
   **`edu.gsu.csc4360.cloud_courier`**. If you register the Android app in the
   console yourself, use that exact ID so FlutterFire can match it.
3. Install the Firebase CLI if needed and run the following commands. Replace
   `YOUR_PROJECT_ID` with the actual Firebase **project ID**.

   ```sh
   flutter pub get
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --project=YOUR_PROJECT_ID --platforms=android --android-package-name=edu.gsu.csc4360.cloud_courier
   ```

   If `flutterfire` is unavailable on Windows, add
   `%LOCALAPPDATA%\Pub\Cache\bin` to PATH and restart your terminal, or run
   `dart pub global run flutterfire_cli:flutterfire configure` with the same
   flags. Allow FlutterFire to overwrite `lib/firebase_options.dart`. If
   `android/app/google-services.json` is missing after configuration, download
   it for the matching Android app from Firebase Project settings and place it
   in `android/app/`. Keep both files aligned with the same Firebase app.
4. Run `flutter run`. In the app, select **Allow notifications** if needed, then
   verify **Notifications** shows **Authorized** and **FCM token** shows
   **Available**. Select **Copy token** for your sender. Copy a fresh token after
   reinstalling or clearing app data. Keep the token out of evidence and Git.

The included Firebase options stub lets the app show a setup screen before
configuration. After changing Firebase configuration, stop the app and rebuild
it. Hot reload does not rerun Firebase initialization.

## 2. Send a message

The exact example messages are in [payloads/valid.json](payloads/valid.json)
and [payloads/invalid.json](payloads/invalid.json). They include a notification
(title and body) and two custom **string** keys. Valid values are
`action=update_ui` and `asset=promo` or `asset=default`.

**Firebase Console.** Open Messaging, create a Firebase Notifications message,
and enter the title and body from the example. In the campaign's **Additional
options**, enter both keys under **Custom data**. Use the test-device send option
with the copied token if your console flow carries those custom data fields into
the test. If that send only transmits title and body, use the HTTP v1 helper
below. The app will show a missing-key diagnostic when custom data is absent.

**Direct HTTP v1 send.** Install Python 3 and Google Cloud CLI. In Google Cloud,
verify the **Firebase Cloud Messaging API** is enabled for the Firebase project
and that your signed-in account has permission `cloudmessaging.messages.create`
(for example, via the Firebase Cloud Messaging API Admin role). Sign in with
`gcloud auth login`, then run:

```sh
python tools/send_message.py YOUR_PROJECT_ID valid
python tools/send_message.py YOUR_PROJECT_ID invalid
```

The script prompts for the token without echoing it. On Windows, use `py` in
place of `python` if needed. Run one send per test from your terminal. An
accepted send request means FCM accepted it for processing. Capture device
evidence to verify the result.

## 3. Run the four device tests

| Test | What to do | What to capture |
| --- | --- | --- |
| T1 · Foreground | Keep the app visible and send `valid`. | `onMessage`, a new message ID, and the promo image and title. A system banner is unnecessary. |
| T2 · Background tap | Press Home, send `valid`, then tap its notification. | The notification and the app showing `onMessageOpenedApp` plus the promo content. |
| T3 · Cold-start tap | After opening the app at least once, remove it from Android Recents, send `valid`, and open it by tapping the new notification. Use the same installed app and avoid Android Settings → Force stop. | The tapped notification and `getInitialMessage` in the app, with promo content. The count starts over on a fresh launch. |
| T4 · Invalid payload | With the promo content showing and the app visible, send `invalid`. | `onMessage`, a fresh message ID, the unsupported-asset diagnostic, and the same promo title and image. |

Use the message ID and count to distinguish deliveries when the repeated valid
payload leaves the image unchanged. If Android Settings force-stops the app,
reopen it once before trying delivery again. If a notification is absent in
T2/T3, check permission, the current token, network access, and the matching
Firebase project. For T3, launch through the notification itself. If a case is
blocked, record the observed behavior and device details.

## 4. Capture evidence and prepare the submission

Use [docs/Reflection_and_Evidence.md](docs/Reflection_and_Evidence.md) for
the three reflection prompts and the four test-result rows. Capture one short
recording or four labeled screenshots. Add a repository link your grader can
open. The template leaves device observations and results for your own run.

## Source guide

- `lib/main.dart` initializes Firebase and registers a top-level background
  callback. Android can invoke it in a separate isolate, where it logs the
  message ID without touching widget state. The on-screen background-tap
  evidence comes from the open event.
- `lib/fcm_service.dart` owns permission and token checks, the foreground and
  notification-tap subscriptions, and the initial-message lookup.
- `lib/courier_state.dart` validates the custom data against the supported
  values. Invalid data updates the diagnostic and delivery metadata while
  preserving the last good announcement.
- `lib/courier_app.dart` renders the announcement, evidence, and device controls.

Run `flutter analyze` and `flutter test` for local code checks. These do not
send a cloud message or replace the four device tests.

Official references

- [Set up FlutterFire](https://firebase.google.com/docs/flutter/setup)
- [Receive FCM messages in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Send through the FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/send/v1-api)
