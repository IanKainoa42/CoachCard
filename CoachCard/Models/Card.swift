import Foundation
import SwiftUI
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var text: String
    var fontSize: CGFloat
    var themeRaw: String
    var glowEnabled: Bool
    var textColorHex: String?
    @Attribute(.externalStorage) var attributedTextData: Data?
    @Attribute(.externalStorage) var drawingData: Data?
    var drawingCanvasWidth: Double?
    var drawingCanvasHeight: Double?
    var createdAt: Date
    var lastUsedAt: Date
    var sortOrder: Int
    var folder: CardFolder?

    var theme: CardTheme {
        get { CardTheme(rawValue: themeRaw) ?? .dark }
        set { themeRaw = newValue.rawValue }
    }

    var resolvedTextColor: Color {
        if let hex = textColorHex {
            return Color(hex: hex)
        }
        return theme.textColor
    }

    var legacyArtboardBold: Bool? {
        let state = legacyArtboardState
        return state?.isBold
    }

    var legacyArtboardUnderline: Bool? {
        let state = legacyArtboardState
        return state?.isUnderlined
    }

    var legacyArtboardDrawingData: Data? {
        let state = legacyArtboardState
        return state?.drawingData
    }

    init(
        text: String,
        fontSize: CGFloat = 150,
        theme: CardTheme = .dark,
        glowEnabled: Bool = true,
        textColorHex: String? = nil,
        attributedTextData: Data? = nil,
        drawingData: Data? = nil,
        drawingCanvasWidth: Double? = nil,
        drawingCanvasHeight: Double? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.text = text
        self.fontSize = fontSize
        self.themeRaw = theme.rawValue
        self.glowEnabled = glowEnabled
        self.textColorHex = textColorHex
        self.attributedTextData = attributedTextData
        self.drawingData = drawingData
        self.drawingCanvasWidth = drawingCanvasWidth
        self.drawingCanvasHeight = drawingCanvasHeight
        self.createdAt = Date()
        self.lastUsedAt = Date()
        self.sortOrder = sortOrder
        self.folder = nil
    }

    private var legacyArtboardState: CardArtboardState? {
        let state = CardArtboardStore.load(for: id)
        return state.isDefault ? nil : state
    }
}

struct CardArtboardState: Codable, Equatable {
    var isBold: Bool = true
    var isUnderlined: Bool = false
    var drawingData: Data?

    var hasDrawing: Bool {
        guard let drawingData else { return false }
        return !drawingData.isEmpty
    }

    var isDefault: Bool {
        isBold && !isUnderlined && !hasDrawing
    }
}

enum CardArtboardStore {
    static func load(for id: UUID) -> CardArtboardState {
        let url = fileURL(for: id)

        guard let data = try? Data(contentsOf: url) else {
            return CardArtboardState()
        }

        return (try? JSONDecoder().decode(CardArtboardState.self, from: data)) ?? CardArtboardState()
    }

    static func save(_ state: CardArtboardState, for id: UUID) {
        guard !state.isDefault else {
            delete(for: id)
            return
        }

        let url = fileURL(for: id)

        do {
            try ensureDirectoryExists()
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save card artboard for \(id): \(error)")
        }
    }

    static func delete(for id: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }

    private static func fileURL(for id: UUID) -> URL {
        directoryURL.appendingPathComponent("\(id.uuidString).json")
    }

    private static var directoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL.appendingPathComponent("CardArtboards", isDirectory: true)
    }

    private static func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}
