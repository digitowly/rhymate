import Foundation
import SwiftUI
import SwiftData

struct RhymesGrid: View {
    var layout: RhymeItemLayout = .grid
    var word: String
    var rhymes: [String]

    @Query private var allFavorites: [FavoriteRhyme]
    @Environment(\.modelContext) private var modelContext

    @State private var sheetDetail: RhymeItem?

    @State private var navigationRhyme: String = ""
    @State private var shouldNavigate: Bool = false

    private var normalizedWord: String { Formatter.normalize(word) }

    func toggleFavorite(_ rhyme: String) {
        if let existing = allFavorites.first(where: { $0.word == normalizedWord && $0.rhyme == rhyme }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteRhyme(word: normalizedWord, rhyme: rhyme))
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
                        if UIDevice.current.userInterfaceIdiom == .phone {
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
                isFavorite: isFavorite($navigationRhyme.wrappedValue),
                toggleFavorite: { toggleFavorite($navigationRhyme.wrappedValue) },
                onDismiss: {sheetDetail = nil}
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
                isFavorite: isFavorite(item.rhyme),
                toggleFavorite: { toggleFavorite(item.rhyme) },
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
