import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeededData") private var hasSeededData = false
    @State private var selectedFolder: CardFolder?

    var body: some View {
        NavigationSplitView {
            FolderListView(selectedFolder: $selectedFolder)
        } detail: {
            NavigationStack {
                GalleryView(folder: selectedFolder)
                    .id(selectedFolder?.id)
            }
        }
        .onAppear {
            seedDataIfNeeded()
        }
    }

    private func seedDataIfNeeded() {
        guard !hasSeededData else { return }
        let seeds: [Card] = [
            Card(text: "KEEP GOING", fontSize: 200, theme: .dark, glowEnabled: true, textColorHex: "#34C759", sortOrder: 0),
            Card(text: "FULL OUT", fontSize: 240, theme: .dark, glowEnabled: true, textColorHex: "#FF3B30", sortOrder: 1),
            Card(text: "AGAIN", fontSize: 250, theme: .dark, glowEnabled: false, sortOrder: 2),
            Card(text: "POINT\nYOUR TOES", fontSize: 150, theme: .gray, glowEnabled: false, sortOrder: 3),
            Card(text: "RESET", fontSize: 220, theme: .dark, glowEnabled: true, textColorHex: "#0A84FF", sortOrder: 4),
            Card(text: "BREATHE", fontSize: 200, theme: .light, glowEnabled: false, sortOrder: 5),
            Card(text: "TIGHT!", fontSize: 240, theme: .dark, glowEnabled: true, textColorHex: "#FFCC00", sortOrder: 6),
            Card(text: "WATER\nBREAK", fontSize: 150, theme: .light, glowEnabled: false, sortOrder: 7),
            Card(text: "LISTEN", fontSize: 220, theme: .gray, glowEnabled: false, sortOrder: 8),
        ]
        for card in seeds { modelContext.insert(card) }
        hasSeededData = true
    }
}
