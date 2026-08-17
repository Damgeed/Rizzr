# Rizzr iOS Professional Build Checklist

## Non-negotiables

- Native SwiftUI app, not a WebView wrapper.
- One source of truth for design tokens.
- Finesse is the production MVP; future modes stay modular and gated.
- No API keys in the app bundle.
- No fake production flows: App Store product IDs must be real before checkout UI claims purchase readiness.
- Privacy claims must match backend behavior and third-party retention settings.

## Phase 0 — Foundation

- [x] XcodeGen project spec
- [x] SwiftUI app entry
- [x] Midnight Aura design tokens
- [x] Mode model aligned with landing page
- [x] Recorder client abstraction
- [x] API client boundary
- [x] Unit-test target scaffold
- [ ] Full Xcode installed and selected
- [ ] First simulator build
- [ ] Real app icon asset

## Phase 1 — Finesse MVP

- [x] Microphone permission UX
- [x] Recording quality validation
- [x] Upload recorded M4A to `/api/transcribe`
- [x] Generate replies via `/api/generate`
- [x] Reply cards: Flirty/Witty/Sweet
- [ ] Copy reply
- [ ] TTS preview wiring
- [x] Error states and retry UX
- [ ] Haptics + accessibility labels

## Phase 2 — Monetization

- [ ] Apple Developer account/app record
- [ ] Bundle ID confirmed: `com.rizzr.app`
- [ ] StoreKit product IDs for monthly/annual Pro
- [ ] Paywall with local StoreKit tests
- [ ] Restore purchases
- [ ] Subscription entitlement model

## Phase 3 — Release hygiene

- [ ] App Store screenshots
- [ ] Privacy nutrition labels
- [ ] Crash reporting decision
- [ ] Analytics decision with consent posture
- [ ] TestFlight build
- [ ] External beta checklist
