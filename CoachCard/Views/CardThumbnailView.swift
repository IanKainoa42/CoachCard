import SwiftUI

struct CardThumbnailView: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(card.theme.backgroundColor)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

            Text(card.text)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(card.theme.textColor)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .padding(12)
                .shadow(
                    color: card.glowEnabled ? card.theme.textColor.opacity(0.6) : .clear,
                    radius: card.glowEnabled ? 4 : 0
                )
        }
        .aspectRatio(1.2, contentMode: .fit)
    }
}
