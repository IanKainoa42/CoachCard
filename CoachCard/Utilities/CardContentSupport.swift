import SwiftUI
import UIKit
import PencilKit

enum CardLayoutMetrics {
    static let referenceScreenSize = UIScreen.main.bounds.size
    static let textPadding: CGFloat = 32
    static let lineLimit = 5
}

struct RichTextStyle {
    var fontSize: CGFloat
    var color: UIColor
    var isBold: Bool
    var isUnderlined: Bool

    var font: UIFont {
        .systemFont(ofSize: max(fontSize, 12), weight: isBold ? .bold : .regular)
    }
}

struct CardCanvasView: View {
    let attributedText: NSAttributedString
    let theme: CardTheme
    let glowEnabled: Bool
    let glowColor: Color
    let drawingData: Data?
    let drawingCanvasSize: CGSize
    var placeholderText: String? = nil
    var placeholderFontSize: CGFloat = 150
    var drawingController: CardDrawingCanvasController? = nil
    var drawingEnabled: Bool = false

    private var hasVisibleText: Bool {
        !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = max(proxy.size.width / max(CardLayoutMetrics.referenceScreenSize.width, 1), 0.01)

            ZStack {
                theme.backgroundColor

                if hasVisibleText {
                    Text(attributedText.cardScaled(by: scale))
                        .minimumScaleFactor(0.05)
                        .lineLimit(CardLayoutMetrics.lineLimit)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(CardLayoutMetrics.textPadding * scale)
                        .modifier(GlowModifier(enabled: glowEnabled, color: glowColor))
                } else if let placeholderText {
                    Text(placeholderText)
                        .font(.system(size: placeholderFontSize * scale, weight: .bold))
                        .foregroundStyle(glowColor.opacity(0.3))
                        .minimumScaleFactor(0.05)
                        .lineLimit(CardLayoutMetrics.lineLimit)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(CardLayoutMetrics.textPadding * scale)
                }

                if let drawingController {
                    CardDrawingCanvasRepresentable(controller: drawingController)
                        .allowsHitTesting(drawingEnabled)
                        .onAppear {
                            drawingController.setCanvasSize(proxy.size)
                            drawingController.setDrawingEnabled(drawingEnabled)
                        }
                        .onChange(of: proxy.size) { _, newSize in
                            drawingController.setCanvasSize(newSize)
                        }
                        .onChange(of: drawingEnabled) { _, newValue in
                            drawingController.setDrawingEnabled(newValue)
                        }
                } else {
                    CardDrawingImageOverlay(
                        drawingData: drawingData,
                        sourceCanvasSize: drawingCanvasSize
                    )
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

struct CardDrawingImageOverlay: View {
    let drawingData: Data?
    let sourceCanvasSize: CGSize

    var body: some View {
        GeometryReader { proxy in
            if let image = drawingImage(for: proxy.size) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    private func drawingImage(for fallbackSize: CGSize) -> UIImage? {
        guard
            let drawingData,
            let drawing = try? PKDrawing(data: drawingData)
        else {
            return nil
        }

        let renderSize: CGSize
        if sourceCanvasSize.width > 0, sourceCanvasSize.height > 0 {
            renderSize = sourceCanvasSize
        } else {
            renderSize = fallbackSize
        }

        return drawing.image(
            from: CGRect(origin: .zero, size: renderSize),
            scale: UIScreen.main.scale
        )
    }
}

final class CardDrawingCanvasController: NSObject, ObservableObject, PKCanvasViewDelegate {
    let canvasView = PKCanvasView()

    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    @Published private(set) var hasDrawing = false
    @Published private(set) var canvasSize: CGSize = .zero

    override init() {
        super.init()

        canvasView.delegate = self
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.contentInsetAdjustmentBehavior = .never
        canvasView.showsVerticalScrollIndicator = false
        canvasView.showsHorizontalScrollIndicator = false
        canvasView.alwaysBounceVertical = false
        canvasView.alwaysBounceHorizontal = false
        canvasView.maximumZoomScale = 1
        canvasView.minimumZoomScale = 1
        canvasView.bouncesZoom = false
    }

    func load(drawingData: Data?) {
        if
            let drawingData,
            let drawing = try? PKDrawing(data: drawingData)
        {
            canvasView.drawing = drawing
        } else {
            canvasView.drawing = PKDrawing()
        }
        refreshUndoState()
    }

    func setTool(_ tool: PKTool) {
        canvasView.tool = tool
    }

    func setCanvasSize(_ size: CGSize) {
        if canvasSize != size {
            canvasSize = size
        }
    }

    func setDrawingEnabled(_ isEnabled: Bool) {
        canvasView.isUserInteractionEnabled = isEnabled
    }

    func clear() {
        canvasView.drawing = PKDrawing()
        refreshUndoState()
    }

    func undo() {
        canvasView.undoManager?.undo()
        refreshUndoState()
    }

    func redo() {
        canvasView.undoManager?.redo()
        refreshUndoState()
    }

    func serializedDrawingData() -> Data? {
        hasDrawing ? canvasView.drawing.dataRepresentation() : nil
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        refreshUndoState()
    }

    private func refreshUndoState() {
        let nextCanUndo = canvasView.undoManager?.canUndo ?? !canvasView.drawing.strokes.isEmpty
        let nextCanRedo = canvasView.undoManager?.canRedo ?? false
        let nextHasDrawing = !canvasView.drawing.strokes.isEmpty

        if canUndo != nextCanUndo {
            canUndo = nextCanUndo
        }
        if canRedo != nextCanRedo {
            canRedo = nextCanRedo
        }
        if hasDrawing != nextHasDrawing {
            hasDrawing = nextHasDrawing
        }
    }
}

struct CardDrawingCanvasRepresentable: UIViewRepresentable {
    @ObservedObject var controller: CardDrawingCanvasController

    func makeUIView(context: Context) -> PKCanvasView {
        controller.canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

@MainActor
final class RichTextEditorController: NSObject, ObservableObject {
    @Published private(set) var attributedText = NSAttributedString(string: "")
    @Published private(set) var selectedStyle = RichTextStyle(
        fontSize: 150,
        color: .white,
        isBold: true,
        isUnderlined: false
    )

    weak var textView: UITextView?

    private var fallbackFontSize: CGFloat = 150
    private var fallbackColor: UIColor = .white
    private var isUpdatingTextView = false

    var plainText: String {
        attributedText.string
    }

    func load(
        attributedText: NSAttributedString,
        fallbackFontSize: CGFloat,
        fallbackColor: UIColor
    ) {
        self.fallbackFontSize = fallbackFontSize
        self.fallbackColor = fallbackColor
        self.attributedText = attributedText.cardNormalized(
            fallbackFontSize: fallbackFontSize,
            fallbackColor: fallbackColor
        )

        let defaultStyle = RichTextStyle(
            fontSize: fallbackFontSize,
            color: fallbackColor,
            isBold: true,
            isUnderlined: false
        )
        selectedStyle = self.attributedText.cardSelectionStyle(
            at: 0,
            fallback: defaultStyle
        )
        syncTextView()
    }

    func updateFallbackColor(_ color: UIColor) {
        fallbackColor = color
        if attributedText.length == 0 {
            selectedStyle.color = color
            syncTypingAttributes()
        }
    }

    func attach(to textView: UITextView) {
        if self.textView !== textView {
            self.textView = textView
            textView.backgroundColor = .clear
            textView.autocapitalizationType = .allCharacters
            textView.autocorrectionType = .no
            textView.spellCheckingType = .no
            textView.smartQuotesType = .no
            textView.smartDashesType = .no
            textView.smartInsertDeleteType = .no
            textView.textAlignment = .center
            textView.font = selectedStyle.font
            textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
            textView.textContainer.lineFragmentPadding = 0
            textView.keyboardDismissMode = .interactive
        }

        syncTextView()
    }

    func textDidChange(_ textView: UITextView) {
        synchronize(from: textView)
    }

    func selectionDidChange(_ textView: UITextView) {
        guard !isUpdatingTextView else { return }
        selectedStyle = selectionStyle(in: textView)
        syncTypingAttributes()
    }

    func toggleBold() {
        updateSelectionStyle { style in
            style.isBold.toggle()
        }
    }

    func toggleUnderline() {
        updateSelectionStyle { style in
            style.isUnderlined.toggle()
        }
    }

    func applyFontSize(_ size: CGFloat) {
        updateSelectionStyle { style in
            style.fontSize = size
        }
    }

    func applyTextColor(_ color: UIColor) {
        updateSelectionStyle { style in
            style.color = color
        }
    }

    private func updateSelectionStyle(_ mutate: (inout RichTextStyle) -> Void) {
        guard let textView else { return }

        var nextStyle = selectedStyle
        mutate(&nextStyle)
        selectedStyle = nextStyle

        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString(string: ""))
            mutableText.addAttributes(attributes(for: nextStyle), range: selectedRange)
            applyCenteredParagraphStyle(to: mutableText, range: selectedRange)

            isUpdatingTextView = true
            textView.attributedText = mutableText
            textView.selectedRange = selectedRange
            isUpdatingTextView = false
            synchronize(from: textView)
        } else {
            syncTypingAttributes()
        }
    }

    private func synchronize(from textView: UITextView) {
        let selectedRange = textView.selectedRange
        let normalized = (textView.attributedText ?? NSAttributedString(string: "")).cardNormalized(
            fallbackFontSize: fallbackFontSize,
            fallbackColor: fallbackColor
        )

        isUpdatingTextView = true
        textView.attributedText = normalized
        let clampedLocation = min(selectedRange.location, normalized.length)
        textView.selectedRange = NSRange(location: clampedLocation, length: 0)
        attributedText = normalized
        selectedStyle = selectionStyle(in: textView)
        syncTypingAttributes()
        isUpdatingTextView = false
    }

    private func syncTextView() {
        guard let textView else { return }

        let selectedRange = textView.selectedRange

        isUpdatingTextView = true
        textView.attributedText = attributedText
        let clampedLocation = min(selectedRange.location, attributedText.length)
        textView.selectedRange = NSRange(location: clampedLocation, length: 0)
        syncTypingAttributes()
        isUpdatingTextView = false
    }

    private func syncTypingAttributes() {
        textView?.typingAttributes = attributes(for: selectedStyle)
    }

    private func selectionStyle(in textView: UITextView) -> RichTextStyle {
        textView.attributedText.cardSelectionStyle(
            at: textView.selectedRange.location,
            fallback: RichTextStyle(
                fontSize: fallbackFontSize,
                color: fallbackColor,
                isBold: true,
                isUnderlined: false
            )
        )
    }

    private func attributes(for style: RichTextStyle) -> [NSAttributedString.Key: Any] {
        [
            .font: style.font,
            .foregroundColor: style.color,
            .underlineStyle: style.isUnderlined ? NSUnderlineStyle.single.rawValue : 0,
            .paragraphStyle: centeredParagraphStyle
        ]
    }

    private func applyCenteredParagraphStyle(
        to attributedText: NSMutableAttributedString,
        range: NSRange
    ) {
        attributedText.addAttribute(.paragraphStyle, value: centeredParagraphStyle, range: range)
    }

    private var centeredParagraphStyle: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        return paragraphStyle
    }
}

struct RichTextEditorView: UIViewRepresentable {
    @ObservedObject var controller: RichTextEditorController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        controller.attach(to: textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        controller.attach(to: uiView)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let controller: RichTextEditorController

        init(controller: RichTextEditorController) {
            self.controller = controller
        }

        func textViewDidChange(_ textView: UITextView) {
            controller.textDidChange(textView)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            controller.selectionDidChange(textView)
        }
    }
}

extension Card {
    var richTextContent: NSAttributedString {
        NSAttributedString.cardDecoded(
            from: attributedTextData,
            fallbackText: text,
            fallbackFontSize: fontSize,
            fallbackColor: UIColor(resolvedTextColor),
            fallbackBold: legacyArtboardBold ?? true,
            fallbackUnderline: legacyArtboardUnderline ?? false
        )
    }

    var richTextPrimaryColor: Color {
        Color(uiColor: richTextContent.cardPrimaryColor(fallback: UIColor(resolvedTextColor)))
    }

    var persistedDrawingData: Data? {
        drawingData ?? legacyArtboardDrawingData
    }

    var storedDrawingCanvasSize: CGSize {
        guard
            let drawingCanvasWidth,
            let drawingCanvasHeight,
            drawingCanvasWidth > 0,
            drawingCanvasHeight > 0
        else {
            return CardLayoutMetrics.referenceScreenSize
        }

        return CGSize(width: drawingCanvasWidth, height: drawingCanvasHeight)
    }
}

extension NSAttributedString {
    static func cardDecoded(
        from data: Data?,
        fallbackText: String,
        fallbackFontSize: CGFloat,
        fallbackColor: UIColor,
        fallbackBold: Bool = true,
        fallbackUnderline: Bool = false
    ) -> NSAttributedString {
        if
            let data,
            let decoded = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
        {
            return decoded.cardNormalized(
                fallbackFontSize: fallbackFontSize,
                fallbackColor: fallbackColor
            )
        }

        return NSAttributedString.cardPlainText(
            fallbackText,
            fontSize: fallbackFontSize,
            color: fallbackColor,
            isBold: fallbackBold,
            isUnderlined: fallbackUnderline
        )
    }

    func cardRTFData() -> Data? {
        guard length > 0 else { return nil }

        return try? data(
            from: NSRange(location: 0, length: length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    func cardPrimaryColor(fallback: UIColor) -> UIColor {
        guard length > 0 else { return fallback }

        var resolvedColor = fallback
        enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: length)) { value, _, stop in
            if let color = value as? UIColor {
                resolvedColor = color
                stop.pointee = true
            }
        }
        return resolvedColor
    }

    func cardScaled(by scale: CGFloat) -> AttributedString {
        let mutableText = NSMutableAttributedString(attributedString: self)
        let safeScale = max(scale, 0.01)

        if mutableText.length > 0 {
            mutableText.enumerateAttribute(.font, in: NSRange(location: 0, length: mutableText.length)) { value, range, _ in
                let font = (value as? UIFont) ?? .systemFont(ofSize: 150, weight: .bold)
                let scaledFont = UIFont(
                    descriptor: font.fontDescriptor,
                    size: max(font.pointSize * safeScale, 8)
                )
                mutableText.addAttribute(.font, value: scaledFont, range: range)
            }
        }

        if let attributedString = try? AttributedString(mutableText, including: \.uiKit) {
            return attributedString
        }

        return AttributedString(mutableText.string)
    }

    func cardNormalized(
        fallbackFontSize: CGFloat,
        fallbackColor: UIColor
    ) -> NSAttributedString {
        let mutableText = NSMutableAttributedString(string: string)
        guard length > 0 else { return mutableText }

        let fullRange = NSRange(location: 0, length: length)
        enumerateAttributes(in: fullRange) { attributes, range, _ in
            let font = (attributes[.font] as? UIFont) ?? .systemFont(ofSize: fallbackFontSize, weight: .bold)
            let color = (attributes[.foregroundColor] as? UIColor) ?? fallbackColor
            let underlineStyle = (attributes[.underlineStyle] as? Int) ?? 0

            mutableText.setAttributes(
                [
                    .font: font,
                    .foregroundColor: color,
                    .underlineStyle: underlineStyle,
                    .paragraphStyle: Self.centeredParagraphStyle
                ],
                range: range
            )
        }

        return mutableText
    }

    func cardSelectionStyle(
        at location: Int,
        fallback: RichTextStyle
    ) -> RichTextStyle {
        guard length > 0 else { return fallback }

        let boundedLocation = min(max(location == length ? max(length - 1, 0) : location, 0), max(length - 1, 0))
        let attributes = attributes(at: boundedLocation, effectiveRange: nil)
        let font = (attributes[.font] as? UIFont) ?? fallback.font
        let color = (attributes[.foregroundColor] as? UIColor) ?? fallback.color
        let underlineStyle = (attributes[.underlineStyle] as? Int) ?? 0

        return RichTextStyle(
            fontSize: font.pointSize,
            color: color,
            isBold: font.fontDescriptor.symbolicTraits.contains(.traitBold),
            isUnderlined: underlineStyle != 0
        )
    }

    private static var centeredParagraphStyle: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        return paragraphStyle
    }

    private static func cardPlainText(
        _ text: String,
        fontSize: CGFloat,
        color: UIColor,
        isBold: Bool,
        isUnderlined: Bool
    ) -> NSAttributedString {
        let style = RichTextStyle(
            fontSize: fontSize,
            color: color,
            isBold: isBold,
            isUnderlined: isUnderlined
        )

        return NSAttributedString(
            string: text,
            attributes: [
                .font: style.font,
                .foregroundColor: color,
                .underlineStyle: isUnderlined ? NSUnderlineStyle.single.rawValue : 0,
                .paragraphStyle: centeredParagraphStyle
            ]
        )
    }
}
