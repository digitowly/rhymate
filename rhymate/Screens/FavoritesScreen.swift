import Foundation
import SwiftUI
import SwiftData

struct FavoritesScreen: View {
    @Environment(\.colorScheme) var colorScheme
    @Query private var favorites: [FavoriteRhyme]

    var body :some View {
        NavigationStack{
            // if user has no stored favortes, display a default message
            if favorites.isEmpty {
                VStack(alignment: .center){
                    Spacer()
                    Text("fallbackFavoritesTitle")
                        .font(.system(.headline))
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    Text("fallbackFavoritesText")
                        .padding(.bottom, 10)
                    Image(systemName: "heart.fill").foregroundColor(.accentColor)
                }.padding(.horizontal, 50)
            }

            ScrollView{
                FavoritesGrid()
                    .padding()
            }
            .navigationTitle("favorites")
        }
    }
}

#Preview {
    FavoritesScreen()
}
