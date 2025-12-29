# AGENTS.md — Codex Instructions (Swift / iOS)

This repository is an iOS app written in Swift (SwiftUI-first unless stated otherwise).  
When working in this repo, act like a senior iOS engineer: prioritize correctness, clean architecture, and a smooth user experience.

---

## 1) Project Goals

- Build a clean, production-grade iOS app with:
  - Consistent, modern UI
  - Predictable navigation and state management
  - Reliable persistence and testable logic
- Prefer maintainable solutions over clever hacks.
- When changing behavior or layout, ensure it works on:
  - iPhone (multiple sizes)
  - Light + Dark mode
  - Dynamic Type (accessibility font sizes)

---

## 2) Code Style + Conventions

### Swift style
- Prefer `struct` + value types.
- Prefer `let` over `var`.
- Keep functions small, single-purpose.
- Use `MARK:` sections for organization (e.g. `// MARK: - Views`, `// MARK: - Actions`).
- Avoid deeply nested closures; refactor into helper methods.

### SwiftUI conventions
- SwiftUI-first approach.
- Prefer composition over inheritance.
- Use:
  - `@State` for local view state
  - `@StateObject` for owned reference state
  - `@ObservedObject` for injected reference state
  - `@EnvironmentObject` only when truly global
  - `@Environment(\.dismiss)` for navigation dismissal
- Avoid “magic” layout: don’t hardcode widths/heights unless necessary.

### Naming
- Views: `SomethingView`
- ViewModels: `SomethingViewModel`
- Services: `SomethingService`
- Models: `Something` (noun)
- Prefer clear, descriptive names over abbreviations.

---

## 3) Architecture

Default to a simple, testable structure:

- **Views**: SwiftUI UI only (no networking inside views)
- **ViewModels**: state + user actions + calling services
- **Services**: persistence, API, system interactions
- **Models**: Codable/Equatable domain models

Avoid over-engineering. Keep it MVVM-ish, lightweight.

---

## 4) Layout + Safe Area Rules

- The app should render full-screen on iPhone by default.
- Do NOT wrap the entire app in padding/rounded-card containers.
- Only apply `.ignoresSafeArea()` for backgrounds when needed.
- Respect safe areas for content (top/bottom bars, home indicator).

When fixing UI issues:
- Use `GeometryReader` sparingly and intentionally.
- Prefer:
  - `Spacer()`
  - `padding`
  - `frame(maxWidth: .infinity, alignment: ...)`
  - `safeAreaInset(edge:)` for bottom buttons if needed

---

## 5) Navigation Rules

- Prefer `NavigationStack`.
- Keep navigation state predictable:
  - Prefer pushing screens rather than presenting everything as modals.
- Modal presentation:
  - Use `.sheet` for secondary flows/settings
  - Use `.fullScreenCover` for immersive “takeover” flows
- Avoid presenting the main/root UI via `.sheet` or UIKit `present(...)`.

---

## 6) Persistence + Storage

Prefer local-first design:

- Use one of:
  - `SwiftData` (if project uses it)
  - `CoreData` (if project uses it)
  - `FileManager` + Codable JSON (for simple data)
  - `UserDefaults` only for small settings/flags
- Data access should live in a service, not inside views.

---

## 7) Error Handling + Logging

- Fail gracefully in UI:
  - show alerts / inline error states
- Use structured logs (e.g. `Logger`) for debugging.
- Never crash on expected issues (missing data, decoding failures, etc.)

---

## 8) Testing Expectations

When adding non-trivial logic, also add tests:

- Unit test ViewModels and Services.
- Keep UI tests minimal unless requested.
- Use deterministic tests (no real network calls).

---

## 9) Build / Tooling Rules

- Do not add new third-party dependencies unless requested.
- Prefer Apple-native APIs.
- Keep the project building cleanly:
  - No warnings
  - No unused code
  - No dead assets

If you change project settings:
- Explain exactly what you changed and why.

---

## 10) How to Submit Changes

When making changes, always provide:

1. A short summary of what you changed
2. Why it fixes the issue
3. Any risks or follow-ups
4. Exact diffs or file-level patches

Example output format:

- ✅ Fix: Root view was presented as a sheet; now set as WindowGroup root
- ✅ UI: removed outer padding causing letterboxing
- ✅ Verified: iPhone 15/SE, Dark mode, Dynamic Type

---

## 11) Debugging Checklist (Use Before Guessing)

When a bug is reported:
- Identify the exact screen and reproduction steps
- Locate the true root cause in code
- Add targeted debug prints/overlays if needed
- Fix minimally, then refactor if appropriate

For layout issues specifically:
- Check for `.sheet/.popover/.formSheet` presentation
- Check for root `.padding()` or constrained `frame(maxWidth:)`
- Confirm safe area behavior
- Verify on device, not just simulator

---

## 12) Boundaries

- Don’t rewrite the app unless asked.
- Keep changes minimal and focused.
- Ask for clarification only if absolutely required; otherwise make best assumptions and proceed.

End of AGENTS.md