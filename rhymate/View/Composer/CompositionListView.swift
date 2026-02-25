import SwiftUI
import SwiftData

struct CompositionListView: View {
    var selectedCollection: CompositionCollection?
    @Binding var selectedComposition: Composition?

    @State private var lastSelectedComposition: Composition?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var allCompositions: [Composition]

    var compositions: [Composition] {
        allCompositions.filter { $0.collection?.id == selectedCollection?.id }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    var body: some View {
        VStack {
            if compositions.isEmpty {
                EmptyStateView(
                    icon: "music.note.list",
                    title: "emptyCompositions.title",
                    description: "emptyCompositions.description"
                ) {
                    Button(action: createComposition) {
                        Label("emptyCompositions.action", systemImage: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(selection: $selectedComposition) {
                    ForEach(compositions) { composition in
                        VStack(alignment: .leading) {
                            Text(composition.displayTitle)
                                .font(.headline)
                            Text(composition.updatedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                        .tag(composition)
                        .accessibilityIdentifier("composition-\(composition.displayTitle)")
                    }
                    .onDelete(perform: deleteComposition)
                }
                .navigationTitle(selectedCollection?.name ?? "Projects")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            createComposition()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .snapshotCompositionSeeding(collection: selectedCollection, compositions: compositions)
        .onDisappear() { saveModelContext() }
        .onChange(of: selectedCollection?.id, initial: true) {
            // On iPad, auto-select when this view appears or when the collection switches
            if horizontalSizeClass == .regular,
               selectedComposition == nil,
               let first = compositions.first {
                selectedComposition = first
            }
        }
        .onChange(of: compositions.count, initial: true) {
            // On iPad, auto-select when a composition appears after seeding (count 0 → 1).
            // In DEBUG builds, -openFirstComposition extends this to compact/iPhone too,
            // allowing the snapshot test to reach the editor without XCUI navigation.
            #if DEBUG
            let shouldAutoSelect = horizontalSizeClass == .regular ||
                ProcessInfo.processInfo.arguments.contains("-openFirstComposition")
            #else
            let shouldAutoSelect = horizontalSizeClass == .regular
            #endif
            if shouldAutoSelect, selectedComposition == nil, let first = compositions.first {
                selectedComposition = first
            }
        }
    }

    private func deleteComposition(at offsets: IndexSet) {
        for index in offsets {
            let composition = compositions[index]

            if selectedComposition?.id == composition.id {
                selectedComposition = nil
            }

            modelContext.delete(composition)
        }
        saveModelContext()
    }

    private func saveModelContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }

    private func createComposition() {
        guard let collection = selectedCollection else { return }
        let newComposition = Composition(
            content: "# ",
            collection: collection
        )
        modelContext.insert(newComposition)
        saveModelContext()
        selectedComposition = newComposition
    }
}
