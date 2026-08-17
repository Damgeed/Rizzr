# Rizzr iOS

Professional iOS foundation for the Rizzr native app.

## Build standard

This app is set up as a native SwiftUI codebase, not a rushed WebView wrapper. The web landing page remains the marketing surface; this iOS app is the product surface.

## Architecture

```text
ios/
├── project.yml                 # XcodeGen project spec
├── RizzrApp/
│   ├── App/                    # App entry + environment
│   ├── DesignSystem/           # Midnight Aura tokens/components
│   ├── Features/               # Product feature modules
│   │   ├── Home/
│   │   ├── Recorder/
│   │   └── Replies/
│   ├── Networking/             # API client + endpoint definitions
│   └── Resources/              # Assets and app config
└── RizzrTests/                 # Unit tests for pure logic
```

## Tooling

The project is defined with XcodeGen for clean, reviewable project generation.

```bash
brew install xcodegen
cd ios
xcodegen generate
open Rizzr.xcodeproj
```

## Current environment note

This machine currently has Apple Command Line Tools but not full Xcode selected, so `xcodebuild` and Simulator are unavailable here. After full Xcode is installed/selected:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -project ios/Rizzr.xcodeproj -scheme Rizzr -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Product-first scope

MVP native app:
1. Finesse mode only: record/upload voice note → generate 3 replies.
2. Text replies first; TTS preview behind a clean API boundary.
3. App Store subscription path prepared, but not wired until product IDs exist.
4. Ghost/Echo/Vibe remain “coming soon” until the Finesse path is production-grade.

## Notes

See `IOS_LAUNCH_PLAN.md` and `PROFESSIONAL_BUILD_CHECKLIST.md` before adding product features.
