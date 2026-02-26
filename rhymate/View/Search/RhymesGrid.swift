import Foundation
import SwiftUI
import SwiftData

struct RhymesGrid: View {
    var layout: RhymeItemLayout = .grid
    var word: String
    var rhymes: [RhymeSuggestion]
    var onRhymeTap: ((String, String) -> Void)?

    @Query private var allFavorites: [FavoriteRhyme]
    @Environment(\.modelContext) private var modelContext

    @State private var sheetDetail: RhymeItem?

    @State private var navigationRhyme: String = ""
    @State private var shouldNavigate: Bool = false

    private var normalizedWord: String { Formatter.normalize(word) }

    func toggleFavorite(_ rhyme: String) {
        let word = normalizedWord
        let descriptor = FetchDescriptor<FavoriteRhyme>(
            predicate: #Predicate { $0.word == word && $0.rhyme == rhyme }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        if let first = existing.first {
            for item in existing { modelContext.delete(item) }
        } else {
            modelContext.insert(FavoriteRhyme(word: word, rhyme: rhyme))
        }
        try? modelContext.save()
    }

    func isFavorite(_ rhyme: String) -> Bool {
        allFavorites.contains { $0.word == normalizedWord && $0.rhyme == rhyme }
    }


    @ViewBuilder
    private var grid: some View {
        let content = LazyVGrid(
            columns:[GridItem(
                .adaptive(minimum: 400),
                spacing: 32
            )],
            spacing: 8
        ){
            ForEach(rhymes) { suggestion in
                RhymeItemView(
                    layout,
                    onPress: {
                        if let onRhymeTap {
                            onRhymeTap(word, suggestion.text)
                        } else if UIDevice.current.userInterfaceIdiom == .phone {
                            sheetDetail = RhymeItem(word: word, rhyme: suggestion.text)
                        } else {
                            navigationRhyme = suggestion.text
                            shouldNavigate = true
                        }
                    },
                    rhyme: suggestion.text,
                    word: word,
                    isAI: suggestion.isAI,
                    isFavorite: isFavorite(suggestion.text),
                    toggleFavorite: { toggleFavorite(suggestion.text) },
                )
            }
        }

        if onRhymeTap == nil {
            content.navigationDestination(isPresented: $shouldNavigate) {
                RhymeDetailView(
                    .detail,
                    word: word,
                    rhyme: $navigationRhyme.wrappedValue,
                    onDismiss: { shouldNavigate = false }
                )
            }
        } else {
            content
        }
    }

    var body: some View {
        grid
            .sheet(
            item: $sheetDetail,
            onDismiss: {sheetDetail = nil}
        )
        { item in
            RhymeDetailView(
                .detail,
                word: word,
                rhyme: item.rhyme,
                onDismiss: {sheetDetail = nil}
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .padding()
    }
}

#Preview {
    RhymesGrid(word: "test", rhymes: [
        RhymeSuggestion(text: "west", isAI: false),
        RhymeSuggestion(text: "best", isAI: false),
        RhymeSuggestion(text: "you've been blessed", isAI: true),
    ])
}
