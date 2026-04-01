# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

CoachCard — silent coaching whiteboard for iPad. Coaches display styled text cards, scores, and freehand drawings full-screen to athletes across a gym.

- **Platform:** iPad only, iOS 17+
- **Stack:** Swift / SwiftUI, SwiftData (persistence), PencilKit (whiteboard)
- **Dependencies:** None (all system frameworks)

## Build

Open `CoachCard.xcodeproj` in Xcode. Single target, no workspace or SPM packages. Build and run on iPad simulator or device:

```bash
xcodebuild -project CoachCard.xcodeproj -scheme CoachCard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build
```

No test target exists yet.

## Architecture

Pure SwiftUI app with SwiftData for local persistence. No networking, no server.

**Data flow:** `@Query` in GalleryView auto-refreshes the card list. `@Environment(\.modelContext)` for inserts/deletes. Navigation via `NavigationStack` + `navigationDestination(for:)`.

**App entry:** `ContentView` wraps `NavigationStack` around `GalleryView` and seeds two demo cards on first launch (`@AppStorage("hasSeededData")`).

**Three display modes** from GalleryView:
1. **DisplayView** — full-screen card text with drawing overlay, swipe between cards, tap to dismiss
2. **ScoreView** — 0.0–10.0 wheel picker with drag-to-scrub gesture and auto-hiding controls
3. **WhiteboardView** — PencilKit canvas via UIViewRepresentable

### Rich Text & Drawing System (CardContentSupport.swift)

The card editor supports per-character rich text (bold, underline, font size, color) plus a drawing overlay. This is the most complex subsystem:

- **RichTextEditorController** — `@MainActor ObservableObject` that owns a `UITextView` reference. Manages `NSAttributedString` state, selection tracking, and style application (bold/underline/size/color). All text normalization goes through `cardNormalized()`.
- **CardDrawingCanvasController** — `ObservableObject` + `PKCanvasViewDelegate` wrapping a `PKCanvasView` for the card editor's "Draw On Top" feature. Separate from WhiteboardView's CanvasManager.
- **CardCanvasView** — shared SwiftUI view used by both CardEditorView (with live drawing controller) and DisplayView (with static drawing image overlay). Handles aspect-ratio scaling of text via `cardScaled(by:)`.
- **Persistence:** Rich text is serialized as RTF via `cardRTFData()` → `Card.attributedTextData` (SwiftData `@Attribute(.externalStorage)`). Drawings stored as `PKDrawing.dataRepresentation()` → `Card.drawingData` with canvas dimensions for proper rescaling.

### Two Separate PencilKit Integrations

1. **WhiteboardView → CanvasManager** — standalone fullscreen drawing canvas. `updateUIView()` intentionally empty; all state flows through the delegate.
2. **CardEditorView → CardDrawingCanvasController** — drawing overlay on card preview. Same empty-`updateUIView` pattern. Supports tool switching (draw/erase), undo/redo, serialization.

Both share the pattern of `NSObject + ObservableObject + PKCanvasViewDelegate` to isolate PencilKit updates from SwiftUI rebuild churn.

### Legacy Artboard Migration

`CardArtboardStore` is a file-based JSON store in Application Support that predates the current rich text system. Cards with legacy artboard data (bold, underline, drawing) are migrated on read via `Card.legacyArtboard*` computed properties. On save, `CardArtboardStore.delete(for:)` cleans up the legacy file.

### Key Design Decisions

- **Brightness management** — all display modes save/restore screen brightness on appear/disappear. This prevents brightness getting stuck at 100% on unexpected dismissal.
- **Card.textColorHex** stores optional custom color as hex string. `resolvedTextColor` falls back to theme default when nil.
- **GlowModifier** uses `.compositingGroup()` to render four shadow layers as a single composited pass.
- **Async patterns** — ScoreView and DisplayView use `Task.sleep` with cancellation instead of Timer for debouncing and auto-hide.
- **Score scrubbing** — ScoreView uses a custom `DragGesture` with accumulated offset tracking (`pointsPerStep: 22`) for tactile score adjustment.
