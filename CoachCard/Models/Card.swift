import SwiftUI
import SwiftData

@Model
final class Card {
    var id: UUID
    var text: String
    var fontSize: CGFloat
    var themeRaw: String
    var glowEnabled: Bool
    var createdAt: Date
    var lastUsedAt: Date
    var sortOrder: Int

    var theme: CardTheme {
        get { CardTheme(rawValue: themeRaw) ?? .dark }
        set { themeRaw = newValue.rawValue }
    }

    init(
        text: String,
        fontSize: CGFloat = 150,
        theme: CardTheme = .dark,
        glowEnabled: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.text = text
        self.fontSize = fontSize
        self.themeRaw = theme.rawValue
        self.glowEnabled = glowEnabled
        self.createdAt = Date()
        self.lastUsedAt = Date()
        self.sortOrder = sortOrder
    }
}
