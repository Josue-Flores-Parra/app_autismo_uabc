# Repository Guidelines

## Project Structure & Module Organization

Appy is a Flutter educational app for autistic learners. `lib/main.dart` initializes Firebase and Provider. Feature code lives in `lib/features/<feature>/`, organized into `view/`, `viewmodel/`, `model/`, and `data/` as needed. Follow the MVVM flow: View → ViewModel → Service/Repository. Shared services and widgets belong in `lib/shared/`; common data access belongs in `lib/data/`; themes live in `lib/core/`.

Flutter tests live in `test/`; Firestore emulator tests live in `firestore-tests/tests/`. Media and fonts are under `assets/`. Architecture, setup, and feature references are in `docs/`.

Firebase configuration lives in `lib/firebase_options.dart` (production) and `lib/firebase_options_dev.dart` (development); `lib/core/app_environment.dart` picks one at startup. Firestore security rules and indexes are `firestore.rules` and `firestore.indexes.json` at the repository root. `tools/firestore-content/` copies learning content from production to development.

## Build, Test, and Development Commands

Use Flutter with Dart compatible with `sdk: ^3.9.2`. Run commands from the repository root unless noted.

- `flutter pub get`: install Flutter dependencies.
- `flutter devices` and `flutter run -d <device-id>`: select a device and run locally against the development project.
- `flutter run -d chrome`: run the web app.
- `flutter build appbundle --release`: build the Android release bundle for Play (production project).
- `flutter build ipa --release`: build the iOS release on macOS (production project).
- Add `--dart-define=APP_ENV=dev` to a release build for QA testers, or `--dart-define=APP_ENV=prod` to point a debug build at production.
- `dart format .` and `flutter analyze`: format Dart and check configured lints.
- `flutter test`: run the Flutter test suite.
- `flutter gen-l10n`: regenerate translations after editing ARB files.

For Firestore tests, install dependencies with `npm ci` inside `firestore-tests/`, then follow `firestore-tests/README.md` for the emulator command and Linux PATH workaround.

## Environments & Firebase

Appy uses two Firebase projects with the same app identifiers (`com.appytea.appy`). `docs/environments.md` is the full reference.

| Environment | Project | CLI alias | Selected by |
| --- | --- | --- | --- |
| Development | `appy-dev-uabc` | `dev` (default) | debug/profile builds, or `APP_ENV=dev` |
| Production | `app-autismo-25f44` | `prod` | release builds, or `APP_ENV=prod` |

- Production holds real families' accounts and children's progress. Do all development, manual testing, and data experiments against `dev`. Never write test data to production, and never run scripts or deploys with `--project prod` unless the user explicitly asks.
- Development builds show a red `DEV` banner. A store build must not show it; build store releases without `APP_ENV`.
- Android does not apply the `com.google.gms.google-services` Gradle plugin. With it, Android starts Firebase from `google-services.json` before Dart runs, and selecting the dev project fails with `duplicate-app`. Do not add it back.
- To regenerate Firebase config, run `flutterfire configure --project=<id> --out=lib/firebase_options.dart` for production or `--out=lib/firebase_options_dev.dart` for development, then remove the google-services plugin lines FlutterFire re-adds to `android/app/build.gradle.kts`. Both files keep the class name `DefaultFirebaseOptions`; `app_environment.dart` imports them with prefixes.
- Deploy rules and indexes with `firebase deploy --only firestore:rules,firestore:indexes --project dev`. Run the `firestore-tests` emulator suite before any production deploy, and update `firestore-tests/tests/` when rules change.
- Development only has learning content (`modules` and their `levels`), copied with `tools/firestore-content/copy-content.js`. Media URLs point to the production Storage bucket by design. The script refuses to write to production.
- Never commit secrets: `android/key.properties`, keystores (`*.jks`), and Firebase service-account keys stay outside the repository. `firebase_options*.dart` client keys are public by design and are committed.

## Coding Style & Naming Conventions

Use two-space indentation and `dart format`; lint rules derive from `flutter_lints` in `analysis_options.yaml`. Use `snake_case.dart` filenames, `UpperCamelCase` types, and `lowerCamelCase` members. Follow existing suffixes such as `*_viewmodel.dart` and `*_screen.dart`.

Use `context.appColors`, `AppRadius`, and `AppFonts` for UI styling. Add user-facing strings to both `lib/l10n/app_es.arb` and `app_en.arb`. Register new assets in `pubspec.yaml` when their paths are not already covered.

# Code and Documentation

For every file you create or modify, follow the relevant guides in `.agents/skills/`. Write code comments and Dart documentation in Spanish.

# Comment Guidelines

- Explain intent, invariants, non-obvious decisions, and meaningful steps in multi-step logic. Put a short comment next to the code it explains, especially inside functions where the reasoning is not clear from the operation alone.
- Do not comment every line or translate code into prose. Avoid comments such as `// Incrementa i` above `i++`; explain why a boundary is checked, how state is preserved, or why an operation must happen in a particular order.
- Add `///` documentation to public Dart classes and members when it clarifies their role, inputs, outputs, or behavior. Use complete, concise Spanish sentences; describe getters as values and methods by their effect.
- Keep comments accurate when behavior changes. Revise or remove stale comments in touched code; include an example only when it makes a subtle rule easier to understand.

## Testing Guidelines

Use `flutter_test` for unit and widget tests; name files `*_test.dart` and mirror feature organization where practical. Add regression coverage for changed behavior. Run individual tests with `flutter test test/puzzle_minigame_test.dart`. No numeric coverage threshold is configured. Firestore rules, KPI, and offline-recovery tests use Node’s test runner against the emulator; `npm test` in `firestore-tests/` runs all three files. Tests run without Firebase: do not add tests that need a real project.

## Commit & Pull Request Guidelines

Branch from and target `develop`; use names like `fix/T16-video-resume`. History uses scoped messages such as `fix(video): retomar video al salir de pantalla`, commonly in Spanish. Keep commits focused.

Follow `.github/PULL_REQUEST_TEMPLATE.md`: summarize changes and affected files, provide concrete QA steps, link issues with `Closes #<number>`, and confirm formatting, lint checks, and manual verification. Wait for team review before merging. Update relevant feature and data-model documentation when changing persistence.
