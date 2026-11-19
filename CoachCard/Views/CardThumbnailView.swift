import SwiftUI

struct CardThumbnailView: View {
    let card: Card

    var body: some View {
        let content = card.richTextContent
        return CardCanvasView(
            attributedText: content,
            theme: card.theme,
            glowEnabled: card.glowEnabled,
            glowColor: card.richTextPrimaryColor(in: content),
            drawingData: card.persistedDrawingData,
            drawingCanvasSize: card.storedDrawingCanvasSize
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .aspectRatio(1.2, contentMode: .fit)
    }
}
