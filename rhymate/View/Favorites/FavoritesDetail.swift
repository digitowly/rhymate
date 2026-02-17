import Foundation
import SwiftUI
import SwiftData

struct FavoritesDetail: View {
    let word: String

    @Query private var allFavorites: [FavoriteRhyme]

    private var rhymes: [String] {
        let normalized = Formatter.normalize(word)
        return allFavorites.filter { $0.word == normalized }.map(\.rhyme)
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
    }
}

#Preview {
    FavoritesDetail(word: "Test")
}
