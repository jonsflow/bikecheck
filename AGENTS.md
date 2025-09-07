# Repository Guidelines

## Project Structure & Modules
- iOS app in `bikecheck/` (SwiftUI + MVVM): `Models/`, `ViewModels/`, `Views/`, `Services/`, entry `bikecheckApp.swift`.
- iOS tests in `bikecheckTests/` (unit) and `bikecheckUITests/` (UI).
- Xcode project in `bikecheck.xcodeproj/`; build configs in `Debug.xcconfig`, `Release.xcconfig`, `Test.xcconfig`.
- Android app in `BikeCheckAndroid/` (Gradle): `app/`, `gradle/`, wrapper `gradlew`.
- CI config in `.github/workflows/test.yml`; architecture diagram in `architecture-diagram.svg`.

## Build, Test, and Development Commands
- iOS unit tests: `xcodebuild test -project bikecheck.xcodeproj -scheme bikecheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -only-testing:bikecheckTests`
- iOS UI tests: `xcodebuild test -project bikecheck.xcodeproj -scheme bikecheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -only-testing:bikecheckUITests`
- Android build (debug): `cd BikeCheckAndroid && ./gradlew assembleDebug`
- Android unit tests: `cd BikeCheckAndroid && ./gradlew test`
- Android instrumentation tests: `cd BikeCheckAndroid && ./gradlew connectedAndroidTest`

## Coding Style & Naming Conventions
- Swift: 4‑space indent; types `UpperCamelCase`, methods/properties `lowerCamelCase`; files match primary type name. Prefer SwiftUI patterns, Combine, and MVVM used here.
- Kotlin/XML: 4‑space indent; classes `UpperCamelCase`, functions/properties `lowerCamelCase`; resource IDs `snake_case`. Keep packages under `com.bikecheck.android`.
- No repo‑enforced linters; follow platform conventions and keep diffs minimal.

## Testing Guidelines
- Frameworks: XCTest (iOS), JUnit/Espresso (Android).
- Place unit tests in `bikecheckTests/` and UI tests in `bikecheckUITests/`; mirror module and type names (e.g., `DataServiceTests` for `DataService`).
- Add tests for new logic and bug fixes; run platform tests locally before PRs.

## Commit & Pull Request Guidelines
- Commits: imperative, present tense, concise (e.g., "Add bike list filtering"). Group related changes; avoid noisy reformat‑only commits.
- PRs: clear summary, linked issues, steps to test, and screenshots for UI changes (iOS/Android). Ensure CI passes.

## Security & Configuration
- Never commit secrets or tokens. iOS: use `*.xcconfig` for keys; Android: use `local.properties`/Gradle properties. Do not commit `local.properties`.
- Strava OAuth: store tokens securely (local device only); avoid logging sensitive data.

## Agent‑Specific Notes
- Keep changes scoped and aligned with MVVM structure. Add new Swift files under the appropriate module folder; Android code under `app/src/...` with consistent packages.
