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
            CardCanvasView(
                attributedText: currentCard.richTextContent,
                theme: currentCard.theme,
                glowEnabled: currentCard.glowEnabled,
                glowColor: currentCard.richTextPrimaryColor,
                drawingData: currentCard.persistedDrawingData,
                drawingCanvasSize: currentCard.storedDrawingCanvasSize
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        } else if value.translation.width > 50, currentIndex > 0 {
                            currentIndex -= 1
                        }
                    }
            )
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .navigationBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if let idx = cards.firstIndex(where: { $0.id == initialCard.id }) {
                currentIndex = idx
            }
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            UIScreen.main.brightness = previousBrightness
        }
        .task(id: currentCard.id) {
            let card = currentCard

            do {
                try await Task.sleep(for: .milliseconds(250))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            card.lastUsedAt = Date()
        }
    }
}
