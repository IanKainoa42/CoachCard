import SwiftUI
import SwiftData

struct FolderListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardFolder.sortOrder) private var folders: [CardFolder]
    @Binding var selectedFolder: CardFolder?

    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var folderToRename: CardFolder?
    @State private var renameFolderName = ""

    var body: some View {
        List(selection: $selectedFolder) {
            NavigationLink(value: nil as CardFolder?) {
                Label("All Cards", systemImage: "square.grid.2x2")
            }

            Section("Folders") {
                ForEach(folders) { folder in
                    NavigationLink(value: folder) {
                        Label(folder.name, systemImage: "folder")
                    }
                    .contextMenu {
                        Button("Rename") {
                            renameFolderName = folder.name
                            folderToRename = folder
                        }
                        Button("Delete", role: .destructive) {
                            if selectedFolder == folder {
                                selectedFolder = nil
                            }
                            modelContext.delete(folder)
                        }
                    }
                }
                .onDelete(perform: deleteFolders)
            }
        }
        .navigationTitle("CoachCard")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    newFolderName = ""
                    showingNewFolderAlert = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createFolder()
            }
            .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .alert("Rename Folder", isPresented: Binding(
            get: { folderToRename != nil },
            set: { if !$0 { folderToRename = nil } }
        )) {
            TextField("Folder Name", text: $renameFolderName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let folder = folderToRename {
                    folder.name = renameFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            .disabled(renameFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let descriptor = FetchDescriptor<CardFolder>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        let maxOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? 0

        let newFolder = CardFolder(name: name, sortOrder: maxOrder + 1)
        modelContext.insert(newFolder)
        selectedFolder = newFolder
    }

    private func deleteFolders(offsets: IndexSet) {
        for index in offsets {
            let folder = folders[index]
            if selectedFolder == folder {
                selectedFolder = nil
            }
            modelContext.delete(folder)
        }
    }
}
