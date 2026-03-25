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
        let keepGoing = Card(text: "KEEP GOING", fontSize: 200, theme: .dark, glowEnabled: true, sortOrder: 0)
        let again = Card(text: "AGAIN", fontSize: 250, theme: .dark, glowEnabled: false, sortOrder: 1)
        modelContext.insert(keepGoing)
        modelContext.insert(again)
        hasSeededData = true
    }
}
