import SwiftUI
import SwiftData

private enum RenameMode: Equatable {
    case create
    case rename(CompositionCollection)
}

struct CompositionCollectionListView: View {
    @Binding var selectedCollection: CompositionCollection?

    @Query(sort: \CompositionCollection.sortOrder)
    private var collections: [CompositionCollection]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode

    @State private var renameMode: RenameMode? = nil
    @State private var nameInput: String = ""
    @State private var collectionToDelete: CompositionCollection? = nil

    var body: some View {
        List(selection: $selectedCollection) {
            if !collections.isEmpty {
                Section(
                    header: Text("Projects").font(.headline)
                ) {
                    ForEach(collections) { collection in
                        CollectionRow(
                            collection: collection,
                            onSelect: { selectedCollection = collection },
                            onRename: {
                                nameInput = collection.name
                                renameMode = .rename(collection)
                            },
                            onDelete: { collectionToDelete = collection }
                        )
                    }
                    .onMove(perform: moveCollections)
                }
            }
        }
        .overlay {
            if collections.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "emptyFolders.title",
                    description: "emptyFolders.description"
                ) {
                    Button {
                        nameInput = ""
                        renameMode = .create
                    } label: {
                        Label("emptyFolders.action", systemImage: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onChange(of: collections.count) {
            if collections.isEmpty {
                editMode?.wrappedValue = .inactive
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    nameInput = ""
                    renameMode = .create
                } label: {
                    Image(systemName: "folder.badge.plus")
                }

                if !collections.isEmpty {
                    EditButton()
                }
            }
        }
        .alert(
            renameMode == .create ? "New Folder" : "Rename Folder",
            isPresented: Binding<Bool>(
                get: { renameMode != nil },
                set: { if !$0 { renameMode = nil } }
            ),
            actions: {
                TextField("Name", text: $nameInput)
                Button("Cancel", role: .cancel) {
                    renameMode = nil
                }
                Button("Save") {
                    switch renameMode {
                    case .create:
                        let maxOrder = collections.map(\.sortOrder).max() ?? 0
                        let newCollection = CompositionCollection(
                            name: nameInput,
                            sortOrder: maxOrder + 1
                        )
                        modelContext.insert(newCollection)
                        selectedCollection = newCollection
                    case .rename(let collection):
                        collection.name = nameInput
                    case .none:
                        break
                    }

                    do {
                        try modelContext.save()
                    } catch {
                        print("Error saving context: \(error)")
                    }

                    renameMode = nil
                }
            }
        )
        .alert(
            "Delete Folder",
            isPresented: Binding<Bool>(
                get: { collectionToDelete != nil },
                set: { if !$0 { collectionToDelete = nil } }
            ),
            actions: {
                Button("Cancel", role: .cancel) {
                    collectionToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let collection = collectionToDelete {
                        if selectedCollection == collection {
                            selectedCollection = nil
                        }
                        modelContext.delete(collection)
                        try? modelContext.save()
                    }
                    collectionToDelete = nil
                }
            },
            message: {
                Text("This will permanently delete the folder and all its compositions.")
            }
        )
    }

    private func deleteCollection(_ collection: CompositionCollection) {
        if selectedCollection == collection {
            selectedCollection = nil
        }
        modelContext.delete(collection)
        try? modelContext.save()
    }

    private func moveCollections(from source: IndexSet, to destination: Int) {
        var ordered = collections.map { $0 }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, collection) in ordered.enumerated() {
            collection.sortOrder = index
        }
        try? modelContext.save()
    }
}

private struct CollectionRow: View {
    let collection: CompositionCollection
    var onSelect: () -> Void
    var onRename: () -> Void
    var onDelete: () -> Void

    @Environment(\.editMode) private var editMode

    private var isEditing: Bool {
        editMode?.wrappedValue == .active
    }

    var body: some View {
        HStack {
            Label(collection.name, systemImage: "folder")
            Spacer()
            if isEditing {
                Menu {
                    Button(action: onRename) {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
    }
}
