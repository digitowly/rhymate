import SwiftUI
import SwiftData

enum RhymeDetailLayout {
    case list
    case detail
    case embedded
}

struct RhymeDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var allFavorites: [FavoriteRhyme]

    @State var definitions: [String] = []
    @State var isLoading: Bool = true
    let layout: RhymeDetailLayout
    let word: String
    let rhyme: String
    var onDismiss: () -> Void

    private var normalizedWord: String { Formatter.normalize(word) }

    private var isFavorite: Bool {
        allFavorites.contains { $0.word == normalizedWord && $0.rhyme == rhyme }
    }

    private func toggleFavorite() {
        let word = normalizedWord
        let rhyme = self.rhyme
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

    init(
        _ layout: RhymeDetailLayout,
        word: String,
        rhyme: String,
        onDismiss: @escaping () -> Void
    ) {
        self.layout = layout
        self.word = word
        self.rhyme = rhyme
        self.onDismiss = onDismiss
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
                            )
                        )
                    }
                }
                .frame(
                    minHeight: 0,
                    maxHeight: .infinity
                )
                .onAppear(perform: {
                    Task {
                        definitions = try await WiktionaryFetcher().getDefinitions(forWord: rhyme)
                        withAnimation{ isLoading = false }
                    }
                })
            }
        case .embedded:
            VStack(alignment: .center) {
                VStack {
                    if isLoading {
                        ProgressView()
                    } else if definitions.isEmpty {
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
                            )
                        )
                    }
                }
                .frame(minHeight: 0, maxHeight: .infinity)
                .onAppear {
                    Task {
                        definitions = try await WiktionaryFetcher().getDefinitions(forWord: rhyme)
                        withAnimation { isLoading = false }
                    }
                }
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
                minWidth: 0,
                maxWidth: .infinity
            )
            .cornerRadius(.infinity)
        }

    }
}
