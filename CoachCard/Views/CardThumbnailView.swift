import SwiftUI

struct CardThumbnailView: View {
    let card: Card

    var body: some View {
        CardCanvasView(
            attributedText: card.richTextContent,
            theme: card.theme,
            glowEnabled: card.glowEnabled,
            glowColor: card.richTextPrimaryColor,
            drawingData: card.persistedDrawingData,
            drawingCanvasSize: card.storedDrawingCanvasSize
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .aspectRatio(1.2, contentMode: .fit)
    }
}
