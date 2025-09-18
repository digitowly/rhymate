import Foundation
import SwiftUI

struct SearchScreen: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private let fetcher = DatamuseFetcher()
    private var historyStorage: SearchHistoryStorage
    
    @State var suggestions: [DatamuseSuggestion] = []
    @State var isLoading: Bool = false
    @State var input: String = ""
    @State var searchError: SearchError? = nil
    @State var searchHistory: [SearchHistoryEntry]
    @State private var navigateToResults: Bool = false
    @State private var debounceTask: Task<Void, Never>? = nil
    
    @Binding var favorites: FavoriteRhymes
    @FocusState private var isSearchFocused: Bool
    
    init(favorites: Binding<FavoriteRhymes>, isSearchFocused: Binding<Bool>) {
        self.historyStorage = SearchHistoryStorage()
        self._favorites = favorites
        self.searchHistory = self.historyStorage.get()
        self.isSearchFocused = self.isSearchFocused
    }
    
    private func storeSearchTerm(_ searchTerm: String) {
        do {
            try historyStorage.mutate(.add, searchTerm)
            withAnimation{ searchHistory = historyStorage.get() }
        } catch {
            print(error)
        }
    }
    
    private func search(searchTerm: String) async {
        let term = Formatter().normalize(searchTerm)
        if term == "" {
            return withAnimation{isLoading = false; searchError = nil; suggestions = [] }
        }
        if term.count < 3 {
            return withAnimation{isLoading = false; searchError = .noResults; suggestions = [] }
        }
        
        do {
            withAnimation{ isLoading = true }
            let suggestionsResponse = try await fetcher.getSuggestions(forWord: term)
            if suggestionsResponse.isEmpty {
                return withAnimation{isLoading = false; searchError = .noResults }
            }
            suggestions = suggestionsResponse
            withAnimation{ isLoading = false; searchError = nil }
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                // Ignore cancelled requests
                return withAnimation{ isLoading = false; searchError = nil}
            }
            return withAnimation{
                isLoading = false
                searchError = ErrorHelper().getSearchError(error: error)
                suggestions = []
            }
        }
    }
    
    var body: some View {
        let searchPlacement: SearchFieldPlacement = horizontalSizeClass == .compact ?
            .automatic : .navigationBarDrawer(displayMode: .automatic)
        
        VStack {
            NavigationStack {
                SearchResultManager(
                    isLoading: $isLoading,
                    input: $input,
                    searchError: $searchError,
                    searchHistory: $searchHistory,
                    suggestions: $suggestions,
                    favorites: $favorites,
                    onRhymesScreenDisappear: storeSearchTerm
                )
                
                .navigationDestination(isPresented: $navigateToResults) {
                    RhymesScreen(
                        word: Formatter().normalize(input),
                        favorites: $favorites,
                        onDisappear: storeSearchTerm
                    )
                }
            }
            .searchable(
                text: $input,
                placement: searchPlacement,
                prompt: "Find a rhyme"
            )
            .onSubmit(of: .search, { navigateToResults = true } )
            .onChange(of: input) { i in
                isLoading = i.isEmpty == false;
                suggestions = []
                debounceTask?.cancel()
                debounceTask = Task { [input = i] in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if !Task.isCancelled {
                        await search(searchTerm: input)
                    }
                }
            }
        }
    }
}

struct PreviewSearchView: View {
    @State var favorites = FavoriteRhymesStorage().getFavoriteRhymes()
    @State var isSearchFocused: Bool = false
    var body: some View {
        SearchScreen(favorites: $favorites, isSearchFocused: $isSearchFocused)
    }
}

#Preview {
    PreviewSearchView()
}
