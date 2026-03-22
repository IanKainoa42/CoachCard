import SwiftUI

struct DisplayView: View {
    let cards: [Card]
    let initialCard: Card

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var previousBrightness: CGFloat = 0.5

    private var currentCard: Card {
        cards[currentIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                currentCard.theme.backgroundColor
                    .ignoresSafeArea()

                Text(currentCard.text)
                    .font(.system(size: currentCard.fontSize, weight: .bold))
                    .foregroundColor(currentCard.resolvedTextColor)
                    .minimumScaleFactor(0.05)
                    .lineLimit(5)
                    .multilineTextAlignment(.center)
                    .padding(32)
                    .modifier(GlowModifier(enabled: currentCard.glowEnabled, color: currentCard.resolvedTextColor))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .statusBarHidden(true)
            .navigationBarHidden(true)
            .onTapGesture {
                dismiss()
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let edgeGuardWidth = geometry.size.width * 0.15
                        let startX = value.startLocation.x

                        // Ignore gestures starting in the edge guard zones
                        if startX < edgeGuardWidth || startX > (geometry.size.width - edgeGuardWidth) {
                            return
                        }

                        if value.translation.width < -50, currentIndex < cards.count - 1 {
                            currentIndex += 1
                            updateLastUsed()
                        } else if value.translation.width > 50, currentIndex > 0 {
                            currentIndex -= 1
                            updateLastUsed()
                        }
                    }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            if let idx = cards.firstIndex(where: { $0.id == initialCard.id }) {
                currentIndex = idx
            }
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            updateLastUsed()
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
        }
    }

    private func updateLastUsed() {
        currentCard.lastUsedAt = Date()
    }
}
