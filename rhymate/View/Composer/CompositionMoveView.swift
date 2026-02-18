import SwiftUI
import SwiftData

struct CompositionMoveView: View {
    @Bindable var composition: Composition
    var onPress: () -> Void = { }
    
    @Query private var collections: [CompositionCollection]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group{
            List {
                ForEach(collections) { collection in
                    Button(action: {
                        self.moveComposition(to: collection)
                        onPress()
                    }) {
                        Label(collection.name, systemImage: "folder")
                    }
                }
            }
        }
        .navigationTitle("Select a Folder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onPress()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }

    }
    
    private func moveComposition(to: CompositionCollection) {
        composition.collection = to
    }
}

#Preview {
//    CompositionMoveView()
}
