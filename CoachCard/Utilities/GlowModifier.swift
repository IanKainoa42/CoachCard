import SwiftUI

struct GlowModifier: ViewModifier {
    let enabled: Bool
    let color: Color

    func body(content: Content) -> some View {
        if enabled {
            content
                .compositingGroup()
                .shadow(color: color.opacity(0.8), radius: 10)
                .shadow(color: color.opacity(0.6), radius: 20)
                .shadow(color: color.opacity(0.4), radius: 40)
                .shadow(color: color.opacity(0.2), radius: 60)
        } else {
            content
        }
    }
}
