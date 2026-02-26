import Foundation
import SwiftUI
import SwiftData

struct FavoritesDetail: View {
    let word: String

    @Environment(\.dismiss) private var dismiss
    @Query private var allFavorites: [FavoriteRhyme]

    private var rhymes: [RhymeSuggestion] {
        let normalized = Formatter.normalize(word)
        return allFavorites
            .filter { $0.word == normalized }
            .map { RhymeSuggestion(text: $0.rhyme, isAI: false) }
    }

    var body: some View {
        VStack(alignment: .leading){
            HStack{
                Text(word)
                    .fontWeight(.black)
                    .font(.system(.title))
                    .padding(3)
            }.padding()
            ScrollView{
                RhymesGrid(
                    layout: .favorite,
                    word: word,
                    rhymes: rhymes
                )
            }
        }
        .onChange(of: rhymes) { _, newValue in
            if newValue.isEmpty { dismiss() }
        }
    }
}

#Preview {
    FavoritesDetail(word: "Test")
}
