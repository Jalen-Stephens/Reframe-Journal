# Reframe Journal Migration Plan (React Native -> SwiftUI)

## App overview
- Platform target: iOS-only (iOS 16+)
- Architecture: SwiftUI + MVVM
- Storage: local only (no networking)
- Theme: light/dark/system preference persisted locally

## Screen mapping (RN -> SwiftUI)
- `HomeScreen` -> `HomeView`
  - Recent entries list (latest 20), “New thought record”, “Continue draft”, Settings button
- `AllEntriesScreen` -> `AllEntriesView`
  - Sectioned list by Today/Yesterday/Older
- `EntryDetailScreen` -> `EntryDetailView`
  - Entry summary, before/after metrics, adaptive response list, edit menu
- `ThoughtResponseDetailScreen` -> `ThoughtResponseDetailView`
  - Read-only adaptive responses for a thought
- Wizard flow (stack):
  - `DateTimeScreen` (WizardStep1) -> `DateTimeView`
  - `SituationScreen` (WizardStep2) -> `SituationView`
  - `AutomaticThoughtsScreen` (WizardStep3) -> `AutomaticThoughtsView`
  - `EmotionsScreen` (WizardStep4) -> `EmotionsView`
  - `AdaptiveResponseScreen` (WizardStep6) -> `AdaptiveResponseView`
  - `OutcomeScreen` (WizardStep7) -> `OutcomeView`
- `SettingsScreen` -> `SettingsView`
  - Theme preference (system/light/dark)

## Shared UI component mapping
- `PrimaryButton` -> `PrimaryButton` (SwiftUI view)
- `LabeledInput` -> `LabeledInput` (SwiftUI view)
- `WizardProgress` -> `WizardProgressView`
- `Accordion` -> `AccordionView`
- `ThoughtCard` -> `ThoughtCardView`
- `EntryListItem` -> `EntryListItemView`
- `SectionCard` -> `SectionCardView`
- `ProgressPill` -> `ProgressPillView`
- `SlimMeterRow` -> `SlimMeterRowView`
- `ChangeSummaryCard` -> `ChangeSummaryCardView`
- `ExpandableText` -> `ExpandableTextView`

## Data model mapping
- `ThoughtRecord` (RN) -> `ThoughtRecord` (Swift struct, Codable)
  - `id: String`
  - `createdAt: String` (ISO 8601)
  - `updatedAt: String` (ISO 8601)
  - `situationText: String`
  - `sensations: [String]`
  - `automaticThoughts: [AutomaticThought]`
  - `emotions: [Emotion]`
  - `thinkingStyles: [String]?` (present but unused in UI)
  - `adaptiveResponses: [String: AdaptiveResponsesForThought]`
  - `outcomesByThought: [String: ThoughtOutcome]`
  - `beliefAfterMainThought: Int?`
  - `notes: String?`

- `AutomaticThought`
  - `id: String`, `text: String`, `beliefBefore: Int`

- `Emotion`
  - `id: String`, `label: String`, `intensityBefore: Int`, `intensityAfter: Int?`

- `ThoughtOutcome`
  - `beliefAfter: Int`, `emotionsAfter: [String: Int]`, `reflection: String?`, `isComplete: Bool?`

- `AdaptiveResponsesForThought`
  - `evidenceText: String`, `evidenceBelief: Int`
  - `alternativeText: String`, `alternativeBelief: Int`
  - `outcomeText: String`, `outcomeBelief: Int`
  - `friendText: String`, `friendBelief: Int`

## Storage mapping
- RN: `expo-sqlite` tables
  - `thought_records` (JSON blobs for arrays/maps)
  - `wizard_draft` (single JSON blob)
- SwiftUI: local JSON file persistence
  - `thought_records.json` (array of `ThoughtRecord`)
  - `wizard_draft.json` (single `ThoughtRecord`)
- Repository API (Swift):
  - `fetchAll()`
  - `fetch(id:)`
  - `upsert(entry:)`
  - `delete(id:)`
  - `fetchDraft()`, `saveDraft(_:)`, `deleteDraft()`

## Validation + business logic
- Percent clamp/validation: 0-100
- Required text validation: `trim().isEmpty == false`
- Wizard flow requirements:
  - Automatic thoughts: at least 1 to proceed
  - Emotions: at least 1 to proceed
  - Adaptive responses: at least 1 response per thought to proceed
  - Outcome: each thought must be marked complete before saving
  - Situation text required to save
- Outcome merge logic: merge defaults with existing outcomes; keep emotion IDs in sync
- Draft behavior: persisted between launches; editing an entry loads into draft

## Libraries to remove + native replacements
- `@react-navigation/*` -> `NavigationStack` with `Route` enum
- `@react-native-community/datetimepicker` -> `DatePicker` (SwiftUI)
- `@react-native-community/slider` -> `Slider` (SwiftUI)
- `@react-native-async-storage/async-storage` -> `@AppStorage` / file storage
- `expo-sqlite` -> JSON file storage (FileManager)
- `react-native-safe-area-context` -> SwiftUI SafeArea / `safeAreaInset`

