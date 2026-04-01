# WYSIWYG Card Editor Preview

## Problem

The CardEditorView preview is a fixed 280pt-tall rounded rectangle with 24pt padding. DisplayView is full-screen with 32pt padding. Because `minimumScaleFactor(0.05)` triggers at different thresholds in each container, the preview does not accurately represent how the card will look full-screen. Text that fits comfortably in the preview may wrap or shrink unexpectedly on the actual display, and vice versa.

## Solution

Replace the fixed-height preview box with a GeometryReader-based preview that matches the device screen's aspect ratio. Scale font size and padding proportionally so text wraps and shrinks at the same thresholds as DisplayView.

## Design

### Changes (CardEditorView only)

1. **Replace the fixed `.frame(height: 280)` preview** with `.aspectRatio(UIScreen.main.bounds.size, contentMode: .fit)` on the preview ZStack. This matches the full screen's proportions. `UIScreen.main.bounds` is used intentionally — DisplayView renders truly full-screen (ignores safe area, hides nav/status bars), so screen size is the correct reference. Split View is out of scope (this is a full-screen coaching app).

2. **Compute a scale factor** via a single GeometryReader inside the preview ZStack:
   - `scale = geo.size.width / UIScreen.main.bounds.width` (rendered preview width / full screen width)

3. **Apply scale to the text rendering:**
   - Font size: `fontSize * scale`
   - Padding: `32 * scale` (matching DisplayView's 32pt padding, not the current 24pt)

4. **Keep identical modifiers to DisplayView:**
   - `.minimumScaleFactor(0.05)`
   - `.lineLimit(5)` (currently preview uses 4 — match DisplayView's 5)
   - `.multilineTextAlignment(.center)` (currently missing from preview — DisplayView has it)
   - `GlowModifier` — shadow radii (10/20/40/60pt) are NOT scaled. The glow in the preview will appear proportionally larger than on the real display. This is acceptable; scaling shadow radii adds complexity for minimal benefit in a preview.

5. **Visual treatment:** Rounded corners + clip on the preview container (it's a miniature, not an actual screen edge).

### Files Modified

- `CoachCard/Views/CardEditorView.swift` — preview section only

### Files NOT Modified

- `DisplayView.swift` — untouched
- All other files — untouched

## Acceptance Criteria

- Preview aspect ratio matches the device screen
- Text at any font size wraps at the same word boundaries in preview and DisplayView
- `minimumScaleFactor` triggers at the same relative text length in both views
- All existing editor functionality (controls, save, cancel, discard alert) unchanged
