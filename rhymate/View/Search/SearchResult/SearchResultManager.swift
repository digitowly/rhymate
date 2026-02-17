import SwiftUI
import SwiftData

struct SearchResultManager: View {
    @Binding var isLoading: Bool
    @Binding var input: String
    @Binding var searchError: SearchError?
    @Binding var searchHistory: [SearchHistoryEntry]
    @Binding var suggestions: [DatamuseSuggestion]
    var onRhymesViewDisappear: ((String) -> Void)?

    @Query(sort: \FavoriteRhyme.word) private var favorites: [FavoriteRhyme]

    private var groupedFavorites: [(word: String, rhymes: [String])] {
        let grouped = Dictionary(grouping: favorites, by: \.word)
        return grouped.keys.sorted().map { word in
            (word: word, rhymes: grouped[word]!.map(\.rhyme))
        }
    }

    var body: some View {
        VStack {
            if isLoading {
                LoadingSpinner()
            } else if let searchError {
                Spacer()
                SearchResultError(input: input, searchError: searchError)
                Spacer()
            } else if !input.isEmpty {
                List {
                    ForEach(suggestions) { suggestion in
                        NavigationLink(
                            destination: RhymesView(
                                word: suggestion.word,
                                onDisappear: onRhymesViewDisappear
                            ),
                            label: { Text(suggestion.word) }
                        )
                    }
                }
            } else if searchHistory.isEmpty && favorites.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "text.magnifyingglass",
                    title: "Find Rhymes",
                    description: "Search for a word to discover rhymes, favorites, and more."
                )
                Spacer()
            } else {
                homeScreen
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var homeScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !searchHistory.isEmpty {
                    recentSearchesSection
                }

                if !groupedFavorites.isEmpty {
                    favoritesSection
                }

                aboutSection
            }
            .padding()
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: SearchHistoryScreen(
                    history: $searchHistory,
                    destination: { entry in
                        RhymesView(word: entry)
                    }
                )) {
                    Text("Show all")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(searchHistory.prefix(10)) { entry in
                        NavigationLink(destination: RhymesView(word: entry.input)) {
                            Text(entry.input)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.quinary)
                                .cornerRadius(.infinity)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorites")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 400))],
                spacing: 4
            ) {
                ForEach(groupedFavorites, id: \.word) { item in
                    NavigationLink(destination: FavoritesDetail(word: item.word)) {
                        FavoritesGridItem(rhymes: item.rhymes, word: item.word)
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        NavigationLink(destination: AboutScreen()) {
            HStack {
                Label("About", systemImage: "info.circle")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.quinary)
            .cornerRadius(12)
        }
    }
}
