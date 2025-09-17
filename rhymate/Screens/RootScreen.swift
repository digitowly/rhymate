import SwiftUI

struct RootScreen: View {
    @State var favorites = FavoriteRhymesStorage().getFavoriteRhymes()
    @State var isRhymeSearchFocused: Bool = false
    
    var body: some View {
        SearchScreen(
            favorites: $favorites,
            isSearchFocused: $isRhymeSearchFocused
        )
    }
}

#Preview {
    RootScreen()
}
