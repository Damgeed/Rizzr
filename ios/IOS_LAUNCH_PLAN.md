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

## Backend/API dependency note

The iOS app points to `https://api.rizzr.com`. If the backend is not deployed and healthy, native app flows that call the API will fail. The app foundation is ready, but the product path needs backend deployment/health verification before TestFlight.
