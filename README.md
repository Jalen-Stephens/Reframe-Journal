# Reframe Journal

A minimal, offline-first React Native (Expo) skeleton for a CBT thought record journal. It includes a 7-step wizard flow, local SQLite persistence, and placeholder screens for future features.

## What’s included
- Expo + React Native + TypeScript
- Stack navigation: Home, Wizard steps 1–7, Entry Detail
- SQLite storage with migrations and CRUD
- In-memory wizard draft with autosave to SQLite
- Basic validation for required fields and 0–100 sliders
- Calm, minimal UI scaffolding

## Privacy
All data stays on your device. No accounts, no analytics, no cloud sync.

## Run locally
1) Install dependencies:

```bash
npm install
```

2) Start Expo:

```bash
npm run start
```

## Future hooks (not implemented)
- AI assist in wizard steps
- Pattern dashboard on Home
- Biometric lock on Entry Detail
