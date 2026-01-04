import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var favorites = FavoriteRhymesStorage().getFavoriteRhymes()
    @State private var selectedComposition: Composition?
    @State private var selectedCollection: CompositionCollection?

    var body: some View {
        TabView {
            NavigationStack {
                SearchScreen(favorites: $favorites)
            }.tabItem {
                Image(systemName: "character.book.closed.fill")
                Text("Rhymes")
            }

            NavigationSplitView {
                CompositionCollectionListView(
                    selectedCollection: $selectedCollection,
                    )
            } content: {
                if let collection = selectedCollection {
                    CompositionListView(
                        selectedCollection: collection,
                        selectedComposition: $selectedComposition,
                        favorites: $favorites
                    )
                } else {
                    Text("Select something")

                }
            } detail: {
                if let composition = selectedComposition {
                    CompositionView(composition: composition, favorites: $favorites)
                } else {
                    Text("Select a composition")
                }
            }.tabItem {
                Image(systemName: "music.pages.fill")
                Text("Projects")
            }
        }
    }
}

#Preview {
    RootView()
}
