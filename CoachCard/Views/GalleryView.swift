import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.sortOrder) private var cards: [Card]
    @State private var searchText = ""
    @State private var showingEditor = false
    @State private var editingCard: Card?
    @State private var showingScore = false
    @State private var showingWhiteboard = false

    private var filteredCards: [Card] {
        if searchText.isEmpty { return cards }
        return cards.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        Group {
            if cards.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredCards) { card in
                            NavigationLink(value: card) {
                                CardThumbnailView(card: card)
                            }
                            .contextMenu {
                                Button("Edit") {
                                    editingCard = card
                                }
                                Button("Move to Top") {
                                    moveToTop(card)
                                }
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(card)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Search cards")
            }
        }
        .navigationTitle("CoachCard")
        .navigationDestination(for: Card.self) { card in
            DisplayView(cards: filteredCards, initialCard: card)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingWhiteboard = true
                } label: {
                    Label("Draw", systemImage: "pencil.tip.crop.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingScore = true
                } label: {
                    Label("Score", systemImage: "number.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingCard = nil
                    showingEditor = true
                } label: {
                    Label("New Card", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            CardEditorView()
        }
        .sheet(item: $editingCard) { card in
            CardEditorView(card: card)
        }
        .fullScreenCover(isPresented: $showingScore) {
            ScoreView()
        }
        .fullScreenCover(isPresented: $showingWhiteboard) {
            WhiteboardView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Tap + to create your first card")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private func moveToTop(_ card: Card) {
        let minOrder = (cards.map(\.sortOrder).min() ?? 0) - 1
        card.sortOrder = minOrder
    }
}
