import Foundation
import SwiftUI
import SwiftData

struct FavoritesScreen: View {
    @Query private var favorites: [FavoriteRhyme]

    var body :some View {
        NavigationStack{
            if favorites.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "emptyFavorites.title",
                    description: "emptyFavorites.description"
                )
            } else {
                ScrollView{
                    FavoritesGrid()
                        .padding()
                }
            }
        }
        .navigationTitle("favorites")
    }
}

#Preview {
    FavoritesScreen()
}
