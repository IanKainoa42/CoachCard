# WYSIWYG Card Editor Preview — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the CardEditorView preview a proportionally accurate miniature of the full-screen DisplayView so font sizing is WYSIWYG.

**Architecture:** Apply `.aspectRatio(UIScreen.main.bounds.size)` to the preview ZStack so it matches screen proportions. Place a single GeometryReader inside the ZStack to read the actual rendered width, then compute `scale = renderedWidth / screenWidth`. Scale font size and padding by that factor so text wraps at identical thresholds.

**Tech Stack:** SwiftUI (GeometryReader), existing Card/CardTheme/GlowModifier

**Spec:** `docs/superpowers/specs/2026-03-23-wysiwyg-preview-design.md`

---

### Task 1: Add GeometryReader and compute scale

**Files:**
- Modify: `CoachCard/Views/CardEditorView.swift:24-43` (body, preview section)

- [ ] **Step 1: Replace the preview section**

Replace everything from `// Live preview` through `.padding()` (lines 27–43 of the current file). The new preview uses:
- `.aspectRatio(UIScreen.main.bounds.size, contentMode: .fit)` on the ZStack to match screen proportions
- A single `GeometryReader` inside the ZStack to read the actual rendered preview width
- `scale = geo.size.width / UIScreen.main.bounds.width` for proportionally correct font and padding

```swift
                // WYSIWYG preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.backgroundColor)

                    GeometryReader { geo in
                        let scale = geo.size.width / UIScreen.main.bounds.width

                        Text(text.isEmpty ? "YOUR TEXT HERE" : text)
                            .font(.system(size: fontSize * scale, weight: .bold))
                            .foregroundColor(text.isEmpty ? effectiveTextColor.opacity(0.3) : effectiveTextColor)
                            .minimumScaleFactor(0.05)
                            .lineLimit(5)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(32 * scale)
                            .modifier(GlowModifier(enabled: glowEnabled && !text.isEmpty, color: effectiveTextColor))
                    }
                }
                .aspectRatio(UIScreen.main.bounds.size, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
```

Key changes from the old preview:
- No outer GeometryReader wrapping the VStack — avoids greedy layout crushing the Form
- `.aspectRatio(UIScreen.main.bounds.size, contentMode: .fit)` on the ZStack replaces `.frame(height: 280)` — matches screen proportions while fitting naturally in the VStack
- Single GeometryReader inside the ZStack reads the actual rendered width (the ZStack's size is already constrained by `.aspectRatio`)
- `scale = geo.size.width / UIScreen.main.bounds.width` — correct ratio since DisplayView is full-screen
- Font size scaled: `fontSize * scale`
- Padding scaled: `32 * scale` (was hardcoded `24`, now matches DisplayView's `32`)
- `.lineLimit(5)` (was `4`, now matches DisplayView)
- `.multilineTextAlignment(.center)` added (was missing, DisplayView has it)
- `.frame(maxWidth: .infinity, maxHeight: .infinity)` on Text centers it within the GeometryReader

Note: `UIScreen.main.bounds` is used intentionally — DisplayView renders truly full-screen (ignores safe area, hides nav/status bars), so the screen size is the correct reference, not the windowed content area.

- [ ] **Step 3: Build and verify**

Run:
```bash
xcodebuild -project CoachCard.xcodeproj -scheme CoachCard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Visual verification**

Open in simulator. Create/edit a card:
1. Type a short word (e.g. "GO") at size 300 — should appear large in preview, proportionally matching full-screen
2. Type a long phrase (e.g. "STICK YOUR LANDING") at size 200 — verify it wraps at the same word boundary in preview and DisplayView
3. Try size 48 — text should be small but centered in both
4. Toggle glow — visible in preview (will appear proportionally thicker, this is expected)
5. Switch themes — background and text color update in preview

- [ ] **Step 5: Commit**

```bash
git add CoachCard/Views/CardEditorView.swift
git commit -m "feat: WYSIWYG preview with aspect-ratio scaling in card editor"
```
