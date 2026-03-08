import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var card: Card?

    @State private var text: String = ""
    @State private var fontSize: CGFloat = 150
    @State private var theme: CardTheme = .dark
    @State private var glowEnabled: Bool = true
    @State private var useCustomColor: Bool = false
    @State private var customColor: Color = .white
    @State private var showDiscardAlert = false

    private var isEditing: Bool { card != nil }
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty }
    private var effectiveTextColor: Color {
        useCustomColor ? customColor : theme.textColor
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
                        TextField("TYPE YOUR MESSAGE", text: $text)
                            .font(.title2)
                            .textInputAutocapitalization(.characters)
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
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if canSave {
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
            .onAppear {
                if let card {
                    text = card.text
                    fontSize = card.fontSize
                    theme = card.theme
                    glowEnabled = card.glowEnabled
                    if let hex = card.textColorHex {
                        useCustomColor = true
                        customColor = Color(hex: hex)
                    }
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let colorHex = useCustomColor ? customColor.hexString : nil
        if let card {
            card.text = trimmed
            card.fontSize = fontSize
            card.theme = theme
            card.glowEnabled = glowEnabled
            card.textColorHex = colorHex
        } else {
            let newCard = Card(text: trimmed, fontSize: fontSize, theme: theme, glowEnabled: glowEnabled, textColorHex: colorHex)
            modelContext.insert(newCard)
        }
        dismiss()
    }
}
