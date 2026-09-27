import SwiftUI
import SwiftData
import StoreKit

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]

    var folder: CardFolder?

    init(folder: CardFolder? = nil) {
        self.folder = folder

        let folderID = folder?.id
        let predicate = #Predicate<Card> { card in
            card.folder?.id == folderID
        }

        _cards = Query(filter: predicate, sort: \Card.sortOrder)
    }

    @State private var searchText = ""
    @State private var showingEditor = false
    @State private var editingCard: Card?
    @State private var showingScore = false
    @State private var showingWhiteboard = false
    @State private var displayingCard: Card?
    @State private var showingMoreApps = false
    @Environment(\.requestReview) private var requestReview
    /// Times a coach has finished a full-screen display session. Ask for a rating after
    /// the 3rd and 10th — by then the app has done its job on a real gym floor.
    @AppStorage("displaySessionCount") private var displaySessionCount: Int = 0

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
                            Button {
                                displayingCard = card
                            } label: {
                                CardThumbnailView(card: card)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit") {
                                    editingCard = card
                                }
                                Button("Move to Top") {
                                    moveToTop(card)
                                }
                                Button("Delete", role: .destructive) {
                                    CardArtboardStore.delete(for: card.id)
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
        .navigationTitle(folder?.name ?? "All Cards")
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
                Menu {
                    Button {
                        editingCard = nil
                        showingEditor = true
                    } label: {
                        Label("New Card", systemImage: "rectangle.portrait.badge.plus")
                    }
                    Button {
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowNewFolderAlert"),
                            object: nil
                        )
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    Divider()
                    Button {
                        showingMoreApps = true
                    } label: {
                        Label("More Coaching Tools", systemImage: "square.grid.2x2")
                    }
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            CardEditorView(initialFolder: folder)
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
        .fullScreenCover(item: $displayingCard, onDismiss: displaySessionEnded) { card in
            DisplayView(cards: filteredCards, initialCard: card)
        }
        .sheet(isPresented: $showingMoreApps) {
            MoreCoachingAppsView()
        }
    }

    private func displaySessionEnded() {
        displaySessionCount += 1
        guard displaySessionCount == 3 || displaySessionCount == 10 else { return }
        // Let the cover finish dismissing so the system prompt isn't dropped.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            requestReview()
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


// MARK: - More Coaching Apps (cross-promotion)

/// One of Ian's other App Store apps. Keep in sync with apps.apple.com/developer/id1864051409.
struct CoachingApp: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let systemImage: String
    let price: String

    var storeURL: URL { URL(string: "https://apps.apple.com/app/id\(id)")! }

    static let others: [CoachingApp] = [
        CoachingApp(id: "6759989262", name: "FormationFlow",
                    tagline: "Plan formations and transitions, animate them, export a printable playbook.",
                    systemImage: "circle.grid.3x3", price: "Free"),
        CoachingApp(id: "6777192892", name: "HitRate: Skill Tracker",
                    tagline: "Count every hit, bobble and fall. Hit % per skill, per group, over the season.",
                    systemImage: "chart.line.uptrend.xyaxis", price: "$2.99"),
        CoachingApp(id: "6766343275", name: "PracticeMix",
                    tagline: "Turn your competition mix into timed practice blocks with reps and rest.",
                    systemImage: "music.note.list", price: "$4.99"),
        CoachingApp(id: "6763985604", name: "Vid-e-Note",
                    tagline: "Draw on any video with Apple Pencil. Mark up stunts and tumbling frame by frame.",
                    systemImage: "pencil.and.scribble", price: "$0.99")
    ]
}

struct MoreCoachingAppsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(CoachingApp.others) { app in
                        Button {
                            openURL(app.storeURL)
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: app.systemImage)
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(app.name).font(.headline)
                                        Spacer()
                                        Text(app.price).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                    }
                                    Text(app.tagline).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(app.name), \(app.price). Opens the App Store.")
                    }
                } header: {
                    Text("From the same coach")
                } footer: {
                    Text("Built at CheerForce San Diego for real practices. Every app works offline with no account.")
                }
            }
            .navigationTitle("More Coaching Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
