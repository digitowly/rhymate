import SwiftUI

enum FavoritesItemLayout {
    case list
    case detail
}

struct FavoritesItemView: View {
    @Environment(\.colorScheme) var colorScheme

    @State var definitions: [String] = []
    @State var isLoading: Bool = true
    let layout: FavoritesItemLayout
    let word: String
    let rhyme: String
    var isFavorite: Bool
    var toggleFavorite: () -> Void
    var onDismiss: () -> Void

    init(
        _ layout: FavoritesItemLayout,
        word: String,
        rhyme: String,
        isFavorite: Bool,
        toggleFavorite: @escaping () -> Void,
        onDismiss: @escaping () -> Void

    ) {
        self.layout = layout
        self.word = word
        self.rhyme = rhyme
        self.isFavorite = isFavorite
        self.onDismiss = onDismiss
        self.toggleFavorite = toggleFavorite
    }

    var body: some View {
        switch layout {
        case .detail:
            VStack(alignment: .center) {
                Spacer()
                HStack(alignment: .center){
                    HStack{
                        FavoritesToggle(
                            action: toggleFavorite,
                            isActivated: isFavorite,
                            size: .large
                        )
                    }
                    .frame(width: 50,alignment: .leading)
                    Spacer()
                    Text(word)
                        .font(.footnote)
                        .fontWeight(.black)
                        .foregroundColor(.secondary)
                    Spacer()
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button("close", action: onDismiss)
                            .frame(width: 50)
                    } else {
                        Text("").frame(width: 50)
                    }
                }
                .padding(.horizontal,20)
                .padding(.top, 20)
                .padding(.bottom, 15)

                Text(rhyme)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 15)

                VStack{
                    if isLoading {
                        ProgressView()
                    }
                    else if definitions.isEmpty {
                        Text("wiktionaryNoDefinitions").foregroundStyle(.secondary)
                    } else {
                        HTMLContentView(
                            htmlElements: definitions,
                            scheme: colorScheme,
                            classNames: """
                            .definition p {
                                padding-bottom: 0.5rem;
                            }
                            """,
                            linkOptions: HTMLContentLinkOptions(
                                baseUrl: "https://en.wiktionary.org/",
                                target: "_blank",
                                color: ACCENT_COLOR
                            )
                        )
                    }
                }
                .frame(
                    minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
                    maxHeight: .infinity
                )
                .onAppear(perform: {
                    Task {
                        definitions = try await WiktionaryFetcher().getDefinitions(forWord: rhyme)
                        withAnimation{ isLoading = false }
                    }
                })
            }
        case .list:
            HStack {
                Text(rhyme)
                    .font(.system(.caption))
                    .fontWeight(.bold)
                    .padding(.horizontal)
                Spacer()
                FavoritesToggle(
                    action: toggleFavorite,
                    isActivated: isFavorite)
                .padding(.horizontal, 12)

            }
            .padding(.vertical, 12)
            .background(.quinary)
            .frame(
                minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
                maxWidth: .infinity
            )
            .cornerRadius(.infinity)
        }

    }
}
