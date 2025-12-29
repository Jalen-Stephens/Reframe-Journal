# Reframe Journal (iOS Native)

This repository now contains the native iOS SwiftUI implementation of Reframe Journal.

## How to build and run in Xcode
1. Open `ReframeJournal.xcodeproj` in Xcode.
2. Select the `ReframeJournal` scheme.
3. Choose an iOS 16+ simulator or a connected device.
4. Build and run (Cmd+R).

## Project structure
- `ReframeJournal/` - SwiftUI app source
- `ReframeJournal.xcodeproj/` - Xcode project
- `legacy-react-native/` - Deprecated React Native codebase (kept for reference)

## Notes
- The iOS app uses local JSON file storage for entries and draft persistence.
- Theme preference (system/light/dark) is stored using AppStorage.
