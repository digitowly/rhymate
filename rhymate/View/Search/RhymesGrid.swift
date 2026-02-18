import Foundation
import SwiftUI
import SwiftData

struct RhymesGrid: View {
    var layout: RhymeItemLayout = .grid
    var word: String
    var rhymes: [String]
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

    var body: some View {
        LazyVGrid(
            columns:[GridItem(
                .adaptive(minimum: 400),
                spacing: 32
            )],
            spacing: 8
        ){
            ForEach(rhymes, id: \.self) { rhyme in
                RhymeItemView(
                    layout,
                    onPress: {
                        if let onRhymeTap {
                            onRhymeTap(word, rhyme)
                        } else if UIDevice.current.userInterfaceIdiom == .phone {
                            sheetDetail = RhymeItem(word: word, rhyme: rhyme)
                        } else {
                            navigationRhyme = rhyme
                            shouldNavigate = true
                        }
                    },
                    rhyme: rhyme,
                    word: word,
                    isFavorite: isFavorite(rhyme),
                    toggleFavorite: { toggleFavorite(rhyme) },
                )
            }
        }
        .navigationDestination(isPresented: $shouldNavigate) {
            FavoritesItemView(
                .detail,
                word: word,
                rhyme: $navigationRhyme.wrappedValue,
                onDismiss: { shouldNavigate = false }
            )
        }
        .sheet(
            item: $sheetDetail,
            onDismiss: {sheetDetail = nil}
        )
        { item in
            FavoritesItemView(
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
    RhymesGrid(word: "test", rhymes: ["west", "best", "chest"])
}
