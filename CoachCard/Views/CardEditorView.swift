import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CardFolder.sortOrder) private var folders: [CardFolder]

    var card: Card?
    var initialFolder: CardFolder?

    @State private var text: String = ""
    @State private var fontSize: CGFloat = 150
    @State private var theme: CardTheme = .dark
    @State private var glowEnabled: Bool = true
    @State private var useCustomColor: Bool = false
    @State private var customColor: Color = .white
    @State private var showDiscardAlert = false
    @State private var selectedFolder: CardFolder?

    private var isEditing: Bool { card != nil }
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var hasUnsavedChanges: Bool {
        editorState != initialState
    }
    private var effectiveTextColor: Color {
        useCustomColor ? customColor : theme.textColor
    }
    private var initialState: EditorState {
        EditorState(card: card, initialFolder: initialFolder)
    }
    private var editorState: EditorState {
        EditorState(
            text: text,
            fontSize: fontSize,
            theme: theme,
            glowEnabled: glowEnabled,
            useCustomColor: useCustomColor,
            customColorHex: useCustomColor ? customColor.hexString : theme.textColor.hexString,
            folderID: selectedFolder?.id
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Live preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.backgroundColor)

                    Text(text.isEmpty ? "YOUR TEXT HERE" : text)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(text.isEmpty ? effectiveTextColor.opacity(0.3) : effectiveTextColor)
                        .minimumScaleFactor(0.05)
                        .lineLimit(4)
                        .padding(24)
                        .modifier(GlowModifier(enabled: glowEnabled && !text.isEmpty, color: effectiveTextColor))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .padding()

                // Controls
                Form {
                    Section {
                        TextEditor(text: $text)
                            .font(.title2.weight(.bold))
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .overlay(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text("TYPE YOUR MESSAGE")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 8)
                                }
                            }
                    }

                    Section {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Size")
                                Spacer()
                                Text("\(Int(fontSize))")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $fontSize, in: 48...300, step: 1)
                        }
                    }

                    Section {
                        Picker("Theme", selection: $theme) {
                            ForEach(CardTheme.allCases, id: \.self) { t in
                                Text(t.displayName).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        Toggle("Custom Font Color", isOn: $useCustomColor)
                        if useCustomColor {
                            ColorPicker("Font Color", selection: $customColor, supportsOpacity: false)
                        }
                    }

                    Section {
                        Toggle("Glow Effect", isOn: $glowEnabled)
                    }

                    Section {
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
                        if hasUnsavedChanges {
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
            .interactiveDismissDisabled(hasUnsavedChanges)
            .onAppear {
                loadState()
            }
        }
    }

    private func save() {
        let trimmed = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let colorHex = useCustomColor ? customColor.hexString : nil
        if let card {
            card.text = trimmed
            card.fontSize = fontSize
            card.theme = theme
            card.glowEnabled = glowEnabled
            card.textColorHex = colorHex
            card.folder = selectedFolder
        } else {
            let newCard = Card(
                text: trimmed,
                fontSize: fontSize,
                theme: theme,
                glowEnabled: glowEnabled,
                textColorHex: colorHex,
                sortOrder: nextSortOrder()
            )
            newCard.folder = selectedFolder
            modelContext.insert(newCard)
        }
        dismiss()
    }

    private func loadState() {
        guard let card else {
            selectedFolder = initialFolder
            return
        }
        text = card.text
        fontSize = card.fontSize
        theme = card.theme
        glowEnabled = card.glowEnabled
        if let hex = card.textColorHex {
            useCustomColor = true
            customColor = Color(hex: hex)
        } else {
            useCustomColor = false
            customColor = card.theme.textColor
        }
        selectedFolder = card.folder
    }

    private func nextSortOrder() -> Int {
        let descriptor = FetchDescriptor<Card>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        let currentTopOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? 0
        return currentTopOrder - 1
    }
}

private struct EditorState: Equatable {
    let text: String
    let fontSize: CGFloat
    let theme: CardTheme
    let glowEnabled: Bool
    let useCustomColor: Bool
    let customColorHex: String
    let folderID: UUID?

    init(
        text: String = "",
        fontSize: CGFloat = 150,
        theme: CardTheme = .dark,
        glowEnabled: Bool = true,
        useCustomColor: Bool = false,
        customColorHex: String = Color.white.hexString,
        folderID: UUID? = nil
    ) {
        self.text = text
        self.fontSize = fontSize
        self.theme = theme
        self.glowEnabled = glowEnabled
        self.useCustomColor = useCustomColor
        self.customColorHex = customColorHex
        self.folderID = folderID
    }

    init(card: Card?, initialFolder: CardFolder? = nil) {
        guard let card else {
            self.init(folderID: initialFolder?.id)
            return
        }

        self.init(
            text: card.text,
            fontSize: card.fontSize,
            theme: card.theme,
            glowEnabled: card.glowEnabled,
            useCustomColor: card.textColorHex != nil,
            customColorHex: card.textColorHex ?? card.theme.textColor.hexString,
            folderID: card.folder?.id
        )
    }
}
