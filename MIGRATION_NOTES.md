# Migration Notes

## What changed
- Replaced the React Native app with a native SwiftUI iOS app in the repo root.
- Implemented MVVM with ObservableObject view models and a local persistence layer.
- Recreated the full screen flow (home, entries, wizard, settings) using SwiftUI navigation.
- Moved the React Native codebase to `legacy-react-native/` and marked it deprecated.

## Storage differences
- RN used SQLite tables (`thought_records`, `wizard_draft`).
- SwiftUI version stores JSON locally:
  - `thought_records.json`
  - `wizard_draft.json`

## Feature parity notes
- All wizard steps, validations, and local persistence are preserved.
- Theme preference (system/light/dark) is preserved using `AppStorage`.
- No Face ID / biometric lock is implemented (per requirement).

## Non-1:1 differences
- UI is implemented with SwiftUI equivalents (layout/spacing may differ slightly).
- SQLite was replaced by JSON file persistence for simplicity.
- Date & Time screen layout updated to use full-height scroll + bottom safe-area button (removed vertical centering).
- Root view now fills the full screen with a background ZStack to avoid a centered-card appearance.

## Legacy app
- The React Native app and dependencies live in `legacy-react-native/` for reference only.
- You can remove the legacy folder if you no longer need it.
