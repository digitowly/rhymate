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

    init() {
        self.historyStorage = SearchHistoryStorage()
        self.searchHistory = self.historyStorage.get()
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
        let term = Formatter.normalize(searchTerm)
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
                searchError = SearchError.from(error)
                suggestions = []
            }
        }
    }

    var body: some View {
        VStack{
            SearchResultManager(
                isLoading: $isLoading,
                input: $input,
                searchError: $searchError,
                searchHistory: $searchHistory,
                suggestions: $suggestions,
                onRhymesViewDisappear: storeSearchTerm
            )
            .navigationDestination(isPresented: $navigateToResults) {
                RhymesView(
                    word: Formatter.normalize(input),
                    onDisappear: storeSearchTerm
                )

                .navigationDestination(isPresented: $navigateToResults) {
                    RhymesView(
                        word: Formatter.normalize(input),
                        onDisappear: storeSearchTerm
                    )
                }
            }
        }
        .searchable(
            text: $input,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Find a rhyme"
        )
        .onSubmit(of: .search, { navigateToResults = true } )
        .onChange(of: input) { _, newValue in
            isLoading = newValue.isEmpty == false;
            suggestions = []
            debounceTask?.cancel()
            debounceTask = Task { [input = newValue] in
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !Task.isCancelled {
                    await search(searchTerm: input)
                }
            }
        }
    }
}

#Preview {
    SearchScreen()
}
