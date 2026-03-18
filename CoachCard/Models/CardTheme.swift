import SwiftUI

enum CardTheme: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case dark
    case light
    case gray

    var textColor: Color {
        switch self {
        case .dark: return .white
        case .light: return .black
        case .gray: return .white
        }
    }

    var backgroundColor: Color {
        switch self {
        case .dark: return .black
        case .light: return .white
        case .gray: return Color(white: 0.25)
        }
    }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .gray: return "Gray"
        }
    }
}
