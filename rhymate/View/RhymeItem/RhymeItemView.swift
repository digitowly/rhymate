import SwiftUI

enum RhymeItemLayout {
    case grid
    case favorite
}

struct RhymeItemView: View {
    let layout: RhymeItemLayout
    let onPress: () -> Void
    private var rhyme: String
    private var word: String
    var isAI: Bool
    var isFavorite: Bool
    var toggleFavorite: () -> Void

    private var isPhrase: Bool { rhyme.contains(" ") }

    init(
        _ layout: RhymeItemLayout = .grid,
        onPress: @escaping () -> Void,
        rhyme: String,
        word: String,
        isAI: Bool = false,
        isFavorite: Bool,
        toggleFavorite: @escaping () -> Void,
    ) {
        self.layout = layout
        self.onPress = onPress
        self.rhyme = rhyme
        self.word = word
        self.isAI = isAI
        self.isFavorite = isFavorite
        self.toggleFavorite = toggleFavorite
    }

    var body: some View {
        HStack {
            if layout == .grid {
                FavoritesToggle(action: toggleFavorite, isActivated: isFavorite)
            }

            Button(action: onPress) {
                HStack(spacing: 8) {
                    if isAI {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    Text(rhyme)
                        .font(.system(.headline))
                        .fontWeight(.bold)
                        .foregroundColor(isAI ? .blue : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !isAI && UIDevice.current.userInterfaceIdiom != .phone {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
            .background(isAI ? AnyShapeStyle(Color.blue.opacity(0.1)) : AnyShapeStyle(.quinary))
            .cornerRadius(isAI ? 18 : 10)
        }
    }
}
