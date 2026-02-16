import SwiftUI
import SwiftData

struct CompositionView: View {
    @Bindable var composition: Composition
    @Binding var favorites: FavoriteRhymes
    
    @State var isMoveSheetVisible: Bool = false
    
    var body: some View {
        Group {
            ScrollView {
                VStack(alignment: .leading) {
                    Spacer(minLength: 32)
                    TextField("Title", text: Binding(
                        get: { composition.title },
                        set: { composition.title = $0 }
                    ))
                    .font(.title)
                    .fontWeight(.bold)
                    Spacer(minLength: 24)
                    ComposeEditor(
                        key: composition.id.uuidString,
                        text: Binding(
                            get: { composition.content },
                            set: { composition.content = $0 }
                        ),
                        chords: Binding(
                            get: { composition.chords },
                            set: { composition.chords = $0 }
                        ),
                        favorites: $favorites,
                        onChange: { composition.updatedAt = Date.now }
                    )
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            isMoveSheetVisible.toggle()
                        }) {
                            Label("Move", systemImage: "arrow.forward.folder.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

            }
            .sheet(isPresented: $isMoveSheetVisible) {
                NavigationStack {
                    CompositionMoveView(
                        composition: composition,
                        onPress: { isMoveSheetVisible.toggle() }
                    )
                }
            }
            .navigationTitle(
                composition.title.isEmpty ? "New Song" : composition.title
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
//#Preview {
//    CompositionView()
//}
