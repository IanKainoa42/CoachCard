# CoachCard

Portfolio synthesis: [/Users/ianrichardson/Knowledge-Hub/library/research/sideline-display-apps-design-pattern.md](/Users/ianrichardson/Knowledge-Hub/library/research/sideline-display-apps-design-pattern.md)

Silent coaching whiteboard for iPad. Flash scores, cues, and hand-drawn messages to athletes from across the gym — no shouting required.

## What It Does

Coaches build a reusable gallery of styled text cards and tap to display them full-screen on their iPad. Athletes read the message from 20+ feet away. A score flipbook lets you dial in 0.0–10.0 without creating individual number cards. A whiteboard mode lets you draw anything freehand.

## Features

- **Card Gallery** — Grid of saved cards. Tap to display, long-press to edit/delete/reorder. Search by text.
- **Card Editor** — Create cards with custom text, font size (48–300pt), theme (Dark/Light/Gray), optional glow effect, and custom font color.
- **Full-Screen Display** — Zero UI chrome. Text fills the screen. Auto-max brightness. Swipe between cards.
- **Score Flipbook** — Wheel picker for 0.0–10.0 in 0.1 increments. Controls auto-hide after 3 seconds so athletes only see the number.
- **Whiteboard** — PencilKit canvas with draw/erase, color picker, pen width, undo/redo. Works with finger or Apple Pencil.
- **Themes** — Dark (white on black), Light (black on white), Gray (white on dark gray). Per-card or per-session.
- **Glow Effect** — Layered shadow halo around text for visibility in gym lighting.
- **Auto Brightness** — Screen maxes to 100% in display modes, restores on exit.

## Tech

- Swift / SwiftUI
- SwiftData (local persistence, no server)
- PencilKit (whiteboard)
- iPad only (iOS 17+)
- No dependencies

## Project Structure

```
CoachCard/
  CoachCardApp.swift
  Models/
    Card.swift            — SwiftData model
    CardTheme.swift       — Dark/Light/Gray enum
  Views/
    ContentView.swift     — Root + first-launch seeding
    GalleryView.swift     — Card grid home screen
    CardThumbnailView.swift
    CardEditorView.swift  — Create/edit with live preview
    DisplayView.swift     — Full-screen card display
    ScoreView.swift       — 0.0–10.0 flipbook
    WhiteboardView.swift  — PencilKit drawing canvas
  Utilities/
    GlowModifier.swift    — Layered shadow glow
    ColorExtensions.swift — Color <-> hex conversion
```
