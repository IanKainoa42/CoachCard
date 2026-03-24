# WYSIWYG Card Editor Preview

## Problem

The CardEditorView preview is a fixed 280pt-tall rounded rectangle with 24pt padding. DisplayView is full-screen with 32pt padding. Because `minimumScaleFactor(0.05)` triggers at different thresholds in each container, the preview does not accurately represent how the card will look full-screen. Text that fits comfortably in the preview may wrap or shrink unexpectedly on the actual display, and vice versa.

## Solution

Replace the fixed-height preview box with a GeometryReader-based preview that matches the device screen's aspect ratio. Scale font size and padding proportionally so text wraps and shrinks at the same thresholds as DisplayView.

## Design

### Changes (CardEditorView only)

1. **Replace the fixed `.frame(height: 280)` preview** with a `GeometryReader` that fills available width and computes height from the screen aspect ratio:
   - `screenAspectRatio = screenHeight / screenWidth`
   - `previewHeight = availableWidth * screenAspectRatio`

2. **Compute a scale factor:**
   - `scale = availableWidth / screenWidth`

3. **Apply scale to the text rendering:**
   - Font size: `fontSize * scale`
   - Padding: `32 * scale` (matching DisplayView's 32pt padding, not the current 24pt)

4. **Keep identical modifiers to DisplayView:**
   - `.minimumScaleFactor(0.05)`
   - `.lineLimit(5)` (currently preview uses 4 — match DisplayView's 5)
   - `.multilineTextAlignment(.center)`
   - `GlowModifier`

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
