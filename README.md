# DINIG

Emergency reporting prototype for Philippine barangay residents, built with Flutter (iOS first). "Dinig" is Tagalog for "hear".

This is a prototype. The sections below separate what works from what is simulated and what is not built. The app's screens carry the same labels.

## What works

- **One-tap SOS with a cancel window.** Manual SOS starts a 5-second countdown based on a wall-clock deadline. Cancel is the largest control. The result screen shows the true delivery state: sending, sent, or saved on the phone and retried when back online (every 30 seconds, up to 10 automatic attempts, plus "Retry now").
- **Phrase check (the context guardrail).** A typed phrase goes through on-device rules in `lib/data/services/phrase_guardrail.dart` and comes back as one of three decisions, with the reason shown:
  - **Send now** (5 s countdown): danger, fire or medical words, or a trigger word with "!".
  - **Ask first** (10 s countdown): a trigger word (Help, Tulong, Saklolo) with no clear context.
  - **No alert**: joke, gaming, study or chore context, or no trigger word and no danger word. The person can still choose "Send anyway".
  Danger words override everyday context. This is a rule-based keyword matcher, not a machine-learning model.
- **Voice trigger (new, switch on Home).** With the switch on, the phone's built-in speech recognition turns what it hears into text. A phrase containing Help, Tulong or Saklolo goes through the same phrase check as a typed one: an emergency starts the same cancel countdown and then sends, a joke or homework phrase does nothing. Seen working on the iOS Simulator in English. It works while the app is open; iOS refuses speech recognition once the app is in the background, so the app posts a "DINIG is not listening" notification and resumes when reopened. Not yet tried on a real iPhone, and Tagalog recognition is untested.
- **Care Mode.** Picture buttons for a child or a person who needs support. Each button says what it does: Hurt, Fire and Lost report to the barangay after a countdown; Scared and Need a grown-up call the caregiver and send no report. A caregiver-approved Help Card is shown on the phone after a report.
- **Guided tour.** The Tour button on Home walks through the controls and presses nothing. In Care Mode it explains the picture buttons instead.
- **Registration** with a labeled demo ID check.
- **Log out.** A button in Settings, and a "Log out" action behind the caregiver's 3-second hold in Care Mode. Both ask first. Logging out erases the profile from the phone and turns the voice trigger off; the resident's row in the database stays.

## Simulated, and labeled as such in the app

| Thing | What it really is |
|---|---|
| Location | The phone's position when you allow location (new, seen on the simulator only). The app asks on reaching Home, never during an alert, and a report waits up to 6 seconds for the position read when its alert began. Without permission, or when the phone has no position, the report carries a fixed demo coordinate plus the registered address. iOS gives an app no position without that permission. A simulator has no GPS: it reports the position set with `xcrun simctl location booted set <lat>,<lon>`. |
| Audio attached to a report | A recording of the alert when the microphone is allowed (new; one upload verified from the simulator). Until then, a generated placeholder tone. Each report says which. |
| ID verification | A demo flow. No camera, no ID data, no check. |
| Sign-in | Any phone number opens a profile. No password or code. |
| Speech to text | Done by the phone's speech engine, not by DINIG. It asks for on-device recognition first and otherwise uses the engine's default, which may send audio to its servers (Apple's on an iPhone). |

Every report row is written with `is_simulated: true`.

## Not built

Listening while the app is in the background or the phone is locked, sound-event detection, server push notifications, responder tracking, and the dispatcher dashboard (a separate project). No privacy or security review has been done; do not put real personal data in this build.

## Stack

Flutter 3.47, Dart 3.13, Material 3. Plugins: `speech_to_text` (voice trigger), `flutter_local_notifications` (local notices), `geolocator` and `geocoding` (location), `record` and `path_provider` (alert recording). Reports and resident profiles are stored in a hosted Postgres database over HTTPS (`lib/data/services/supabase_service.dart`). Layout: `lib/data` (models, services, repository), `lib/ui` (view model, screens, components).

## Run

```bash
flutter pub get
flutter run
```

## Test

Do **not** run the bare `flutter test`: `test/supabase_service_test.dart` writes a real row and a file to the live database on every run. Run the offline files:

```bash
flutter analyze
flutter test test/outbox_test.dart test/dispatch_test.dart test/listening_test.dart test/care_mode_test.dart test/honesty_test.dart test/widget_test.dart test/phrase_guardrail_test.dart test/guide_tour_test.dart
flutter build ios --simulator --no-codesign
```
