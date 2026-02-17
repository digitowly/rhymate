import SwiftUI
import SwiftData

struct CompositionListView: View {
    var selectedCollection: CompositionCollection?
    @Binding var selectedComposition: Composition?
    @Binding var favorites: FavoriteRhymes
    
    @State private var lastSelectedComposition: Composition?
    
    @Environment(\.modelContext) private var modelContext
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
                            Text(composition.title)
                                .font(.headline)
                            Text(composition.updatedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(composition)
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
        .onDisappear() { saveModelContext() }
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
            title: "Untitled",
            collection: collection
        )
        modelContext.insert(newComposition)
        saveModelContext()
        selectedComposition = newComposition
    }
}
