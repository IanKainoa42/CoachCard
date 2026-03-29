import SwiftUI
import SwiftData
import PencilKit

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CardFolder.sortOrder) private var folders: [CardFolder]

    var card: Card?
    var initialFolder: CardFolder?

    @StateObject private var richTextController = RichTextEditorController()
    @StateObject private var drawingController = CardDrawingCanvasController()
    @State private var theme: CardTheme = .dark
    @State private var glowEnabled: Bool = true
    @State private var drawingTool: CardDrawingTool = .draw
    @State private var drawingColor: Color = .white
    @State private var drawingWidth: CGFloat = 8
    @State private var showDiscardAlert = false
    @State private var selectedFolder: CardFolder?

    private var isEditing: Bool { card != nil }
    private var trimmedPlainText: String {
        richTextController.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool { !trimmedPlainText.isEmpty }
    private var hasEditorContent: Bool {
        richTextController.attributedText.length > 0
            || drawingController.hasDrawing
            || theme != .dark
            || !glowEnabled
    }
    private var previewGlowColor: Color {
        Color(richTextController.attributedText.cardPrimaryColor(fallback: UIColor(theme.textColor)))
    }
    private var selectedTextColor: Binding<Color> {
        Binding(
            get: { Color(richTextController.selectedStyle.color) },
            set: { richTextController.applyTextColor(UIColor($0)) }
        )
    }
    private var selectedFontSize: Binding<Double> {
        Binding(
            get: { Double(richTextController.selectedStyle.fontSize) },
            set: { richTextController.applyFontSize(CGFloat($0)) }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CardCanvasView(
                    attributedText: richTextController.attributedText,
                    theme: theme,
                    glowEnabled: glowEnabled,
                    glowColor: previewGlowColor,
                    drawingData: nil,
                    drawingCanvasSize: drawingController.canvasSize,
                    placeholderText: "YOUR TEXT HERE",
                    placeholderFontSize: max(richTextController.selectedStyle.fontSize, 48),
                    drawingController: drawingController,
                    drawingEnabled: true
                )
                .aspectRatio(UIScreen.main.bounds.size, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()

                Form {
                    Section("Message") {
                        ZStack(alignment: .topLeading) {
                            if richTextController.plainText.isEmpty {
                                Text("TYPE YOUR MESSAGE")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 10)
                            }

                            RichTextEditorView(controller: richTextController)
                                .frame(minHeight: 160)
                        }
                    }

                    Section("Formatting") {
                        HStack(spacing: 12) {
                            formattingButton(
                                "Bold",
                                systemImage: "bold",
                                isActive: richTextController.selectedStyle.isBold
                            ) {
                                richTextController.toggleBold()
                            }

                            formattingButton(
                                "Underline",
                                systemImage: "underline",
                                isActive: richTextController.selectedStyle.isUnderlined
                            ) {
                                richTextController.toggleUnderline()
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Font Size")
                                Spacer()
                                Text("\(Int(richTextController.selectedStyle.fontSize))")
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: selectedFontSize, in: 48...300, step: 1)
                        }

                        ColorPicker("Text Color", selection: selectedTextColor, supportsOpacity: false)
                    }

                    Section("Card") {
                        Picker("Theme", selection: $theme) {
                            ForEach(CardTheme.allCases, id: \.self) { currentTheme in
                                Text(currentTheme.displayName).tag(currentTheme)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Glow Effect", isOn: $glowEnabled)
                    }

                    Section("Draw On Top") {
                        Picker("Tool", selection: $drawingTool) {
                            ForEach(CardDrawingTool.allCases) { tool in
                                Text(tool.title).tag(tool)
                            }
                        }
                        .pickerStyle(.segmented)

                        if drawingTool == .draw {
                            ColorPicker("Marker Color", selection: $drawingColor, supportsOpacity: false)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Marker Width")
                                    Spacer()
                                    Text("\(Int(drawingWidth))")
                                        .foregroundStyle(.secondary)
                                }

                                Slider(value: $drawingWidth, in: 2...30, step: 1)
                            }
                        }

                        HStack {
                            Button("Undo") {
                                drawingController.undo()
                            }
                            .disabled(!drawingController.canUndo)

                            Button("Redo") {
                                drawingController.redo()
                            }
                            .disabled(!drawingController.canRedo)

                            Spacer()

                            Button("Clear", role: .destructive) {
                                drawingController.clear()
                            }
                            .disabled(!drawingController.hasDrawing)
                        }
                    }

                    Section("Folder") {
                        Picker("Folder", selection: $selectedFolder) {
                            Text("None").tag(nil as CardFolder?)
                            ForEach(folders) { folder in
                                Text(folder.name).tag(folder as CardFolder?)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasEditorContent {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
            .alert("Discard changes?", isPresented: $showDiscardAlert) {
                Button("Keep Editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            }
            .interactiveDismissDisabled(hasEditorContent)
            .onAppear {
                loadCardState()
                updateDrawingTool()
            }
            .onChange(of: theme) {
                richTextController.updateFallbackColor(UIColor(theme.textColor))
            }
            .onChange(of: drawingTool) {
                updateDrawingTool()
            }
            .onChange(of: drawingColor) {
                if drawingTool == .draw {
                    updateDrawingTool()
                }
            }
            .onChange(of: drawingWidth) {
                if drawingTool == .draw {
                    updateDrawingTool()
                }
            }
        }
    }

    private func formattingButton(
        _ title: String,
        systemImage: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(isActive ? .accentColor : .secondary.opacity(0.25))
    }

    private func loadCardState() {
        if let card {
            theme = card.theme
            glowEnabled = card.glowEnabled
            selectedFolder = card.folder

            richTextController.load(
                attributedText: card.richTextContent,
                fallbackFontSize: card.fontSize,
                fallbackColor: UIColor(card.resolvedTextColor)
            )
            drawingController.load(drawingData: card.persistedDrawingData)
            drawingColor = card.richTextPrimaryColor
        } else {
            selectedFolder = initialFolder
            richTextController.load(
                attributedText: NSAttributedString(string: ""),
                fallbackFontSize: 150,
                fallbackColor: UIColor(theme.textColor)
            )
            drawingController.load(drawingData: nil)
            drawingColor = theme.textColor
        }
    }

    private func updateDrawingTool() {
        switch drawingTool {
        case .draw:
            drawingController.setTool(
                PKInkingTool(.marker, color: UIColor(drawingColor), width: drawingWidth)
            )
        case .erase:
            drawingController.setTool(PKEraserTool(.bitmap))
        }
    }

    private func save() {
        let normalizedText = richTextController.attributedText.cardNormalized(
            fallbackFontSize: richTextController.selectedStyle.fontSize,
            fallbackColor: UIColor(theme.textColor)
        )
        let primaryColor = normalizedText.cardPrimaryColor(fallback: UIColor(theme.textColor))
        let drawingSize = drawingController.canvasSize

        let targetCard: Card
        if let card {
            targetCard = card
        } else {
            let newCard = Card(text: trimmedPlainText, sortOrder: nextSortOrder())
            modelContext.insert(newCard)
            targetCard = newCard
        }

        targetCard.text = trimmedPlainText
        targetCard.fontSize = richTextController.selectedStyle.fontSize
        targetCard.theme = theme
        targetCard.glowEnabled = glowEnabled
        targetCard.textColorHex = Color(primaryColor).hexString
        targetCard.attributedTextData = normalizedText.cardRTFData()
        targetCard.drawingData = drawingController.serializedDrawingData()
        targetCard.drawingCanvasWidth = drawingSize.width > 0 ? Double(drawingSize.width) : nil
        targetCard.drawingCanvasHeight = drawingSize.height > 0 ? Double(drawingSize.height) : nil
        targetCard.folder = selectedFolder
        CardArtboardStore.delete(for: targetCard.id)

        dismiss()
    }

    private func nextSortOrder() -> Int {
        let descriptor = FetchDescriptor<Card>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        let currentTopOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? 0
        return currentTopOrder - 1
    }
}

private enum CardDrawingTool: String, CaseIterable, Identifiable {
    case draw
    case erase

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draw:
            return "Draw"
        case .erase:
            return "Erase"
        }
    }
}
