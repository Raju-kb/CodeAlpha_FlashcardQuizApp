# Flashcard Quiz App

A Flutter mobile app for studying with flashcards — built by Raju K B for the **CodeAlpha App Development Internship (Task 1)**.

Each flashcard has a question on the front and the answer on the back. Tap the card or the **Show Answer** button to flip it, move through the deck with **Next** and **Previous**, and add, edit or delete your own cards.

## Features

- Flashcard with question on the front and answer on the back, with an animated flip
- **Show Answer** / **Hide Answer** button, or tap the card to flip it
- **Next** and **Previous** buttons, with a "Card 3 of 10" progress label and progress bar
- **Add** flashcards with your own question and answer
- **Edit** and **Delete** flashcards, from the card on screen or from the Manage Cards list
- **Shuffle** the deck, and **Reset to Defaults** to restore the 10 starter cards
- Cards are saved on the device, so your deck survives closing the app
- 10 starter study cards included (general knowledge, science and geography)

## Tech stack

- **Flutter** (Dart) with Material 3
- `shared_preferences` for on-device storage — no account, no server needed

## Project structure

```
flashcard-quiz-app/
├── pubspec.yaml            # name: flashcard_quiz_app
├── lib/
│   ├── main.dart           # the app: deck, flip animation, add/edit/delete
│   └── data.dart           # Flashcard model and the 10 starter cards
├── test/
│   └── widget_test.dart    # smoke test: open the app, flip a card
├── android/                # Android app (applicationId com.codealpha.flashcardquizapp)
├── ios/Runner/Info.plist   # iOS app metadata
└── README.md
```

## Getting started

You need the Flutter SDK (3.10 or newer) installed.

```bash
flutter pub get
flutter run
```

Run it on an Android emulator, a connected phone, or in Chrome with `flutter run -d chrome`.

## Tests

```bash
flutter test
```

## Build an APK (Android)

```bash
flutter build apk --release
```

The APK is produced at `build/app/outputs/flutter-apk/app-release.apk`.

## About this project

This is Task 1 of the CodeAlpha App Development Internship — [codealpha.tech](https://www.codealpha.tech).
