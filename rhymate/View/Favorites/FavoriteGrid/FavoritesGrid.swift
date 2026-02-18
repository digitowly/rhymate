import SwiftUI
import SwiftData

struct FavoritesGrid: View {
    @Query(sort: \FavoriteRhyme.word) private var favorites: [FavoriteRhyme]

    private var groupedByWord: [String: [FavoriteRhyme]] {
        Dictionary(grouping: favorites, by: \.word)
    }

    var body: some View {
        LazyVGrid(
            columns:[GridItem(
                .adaptive(minimum: 400)
            )],
            spacing: 4
        ){
            ForEach(Array(groupedByWord.keys.sorted()), id: \.self) { word in
                if let entries = groupedByWord[word], !entries.isEmpty {
                    NavigationLink(
                        destination: FavoritesDetail(word: word),
                        label: {
                        FavoritesGridItem(
                            rhymes: entries.map(\.rhyme),
                            word: word,
                        )
                    })
                }
            }
        }
    }
}

#Preview {
    FavoritesGrid()
}
