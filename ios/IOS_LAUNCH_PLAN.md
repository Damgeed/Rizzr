# Rizzr iOS Launch Plan

## Current decision

Start the native iOS app now. The landing page is visually strong enough to support the next phase; further micro-polish should not block product work.

## Quality bar

Rizzr iOS should be treated as a production product from day one:

- Native SwiftUI, not a WebView wrapper.
- Modular feature boundaries: Home, Recorder, Replies, Networking, DesignSystem.
- Midnight Aura design tokens carried over from the web UI.
- API keys never shipped in the app.
- Finesse first; Ghost/Echo/Vibe remain gated until Finesse is excellent.
- App Store purchase flow only after real product IDs exist.
- Every build phase requires verification before commit.

## Phase 0 — Foundation complete in this repo

- XcodeGen project specification.
- SwiftUI app entry.
- App environment/dependency injection.
- Design system tokens and glass components.
- Mode carousel model and UI.
- Recorder client abstraction with AVAudioRecorder implementation.
- API client boundary for `/api/generate`.
- App icon asset derived from the current Rizzr icon.
- Unit-test target scaffold.
- Professional build checklist.

## Phase 0.5 — Safe product hardening complete in this repo

- Production feature flags keep Finesse live and Ghost/Echo/Vibe gated.
- Recorder state now preserves a validated recording session instead of discarding the capture.
- Voice notes shorter than 1 second or longer than 2 minutes are rejected before API work.
- API client now sets timeouts and explicit `Accept` headers.
- Unit tests cover feature gating and recording duration policy.

## Immediate next steps after full Xcode is available

1. Install/select full Xcode:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
2. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```
3. Generate project:
   ```bash
   cd ios && xcodegen generate
   ```
4. Build on simulator:
   ```bash
   xcodebuild -project ios/Rizzr.xcodeproj -scheme Rizzr -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```
5. Begin Finesse MVP implementation:
   - record M4A
   - transcribe
   - generate 3 replies
   - render reply cards
   - copy reply
   - add TTS preview behind API boundary

## Phase 1 — Finesse real API path started

- Backend exposes typed `/api/transcribe` and `/api/generate` endpoints with a shared `{success,data,error}` envelope.
- iOS uploads recorded M4A audio as multipart form data to `/api/transcribe`.
- iOS sends the returned transcript to `/api/generate`.
- iOS renders the three returned reply cards: flirty, witty, sweet.
- Reply cards support copy/share actions, copied-state feedback, and accessibility labels.
- No App Store, account, Echo, Ghost, Vibe, or TTS production claims are wired yet.

## Backend/API dependency note

The iOS app points to `https://api.rizzr.com`. If the backend is not deployed and healthy, native app flows that call the API will fail. The app foundation is ready, but the product path needs backend deployment/health verification before TestFlight.
