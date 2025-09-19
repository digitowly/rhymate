import SwiftUI

struct SearchResultManager: View {
    @Binding var isLoading: Bool
    @Binding var input: String
    @Binding var searchError: SearchError?
    @Binding var searchHistory: [SearchHistoryEntry]
    @Binding var suggestions: [DatamuseSuggestion]
    @Binding var favorites: FavoriteRhymes
    var onRhymesViewDisappear: ((String) -> Void)?
    
    var body: some View {
        VStack {
            if isLoading {
                LoadingSpinner()
            } else if let searchError {
                Spacer()
                SearchResultError(input: input, searchError: searchError)
                Spacer()
            } else {
                List {
                    if (input.isEmpty) {
                        Section(){
                            NavigationLink(destination: SearchHistoryScreen(
                                history: $searchHistory,
                                destination: { entry in
                                    RhymesView(word: entry,favorites: $favorites)
                                }
                            ), label: {
                                Label("History", systemImage: "clock")
                            })
                            NavigationLink(destination: FavoritesScreen(favorites: $favorites), label: {
                                Label("Favorites", systemImage: "suit.heart")
                            })
                        }
                        Section(){
                            NavigationLink(destination: AboutScreen(), label: {
                                Label("About", systemImage: "info.circle")
                            })
                        }
                    }
                    ForEach(suggestions) { suggestion in
                        NavigationLink(
                            destination: RhymesView(
                                word: suggestion.word,
                                favorites: $favorites,
                                onDisappear: onRhymesViewDisappear
                            ),
                            label: { Text(suggestion.word)}
                        )
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
