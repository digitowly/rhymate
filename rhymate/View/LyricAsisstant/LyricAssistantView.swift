import SwiftUI
import SwiftData

struct LyricAssistantView: View {
    @Binding var text: String
    var hasAutoSubmit = false
    var onSearchTermChange: ((String) -> Void)?

    @State private var searchText: String = ""
    @State private var selectedRhyme: RhymeItem?
    @FocusState private var isInputFocused: Bool

    private var words: [String] {
        ComposerLogic.words(in: text)
    }

    private var isSendButtonVisible: Bool {
        ComposerLogic.isSendButtonVisible(words: words, currentSearchText: searchText)
    }

    private func submit(_ word: String) {
        searchText = word
        selectedRhyme = nil
        onSearchTermChange?(word)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let selected = selectedRhyme {
                ZStack {
                    Text(selected.rhyme)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    HStack {
                        Button(action: { selectedRhyme = nil }) {
                            Label("Back", systemImage: "chevron.left")
                                .font(.subheadline)
                        }
                        Spacer()
                        InlineFavoritesToggle(word: selected.word, rhyme: selected.rhyme)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                FavoritesItemView(
                    .embedded,
                    word: selected.word,
                    rhyme: selected.rhyme,
                    onDismiss: { selectedRhyme = nil }
                )
            } else if searchText.isEmpty {
                Spacer()
                LyricAssistantEmptyView()
                Spacer()
            } else {
                ScrollView {
                    RhymesView(word: searchText, onRhymeTap: { word, rhyme in
                        selectedRhyme = RhymeItem(word: word, rhyme: rhyme)
                    })
                }
                .transaction { $0.animation = nil }
            }

            Divider()
            inputBar
                .padding(.top, 8)
        }
        .onAppear {
            if hasAutoSubmit, words.count == 1, let word = words.first {
                searchText = word
                onSearchTermChange?(word)
            }
            isInputFocused = true
        }
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            if words.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(words, id: \.self) { word in
                            Button(word) { submit(word) }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.quinary)
                                .clipShape(Capsule())
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type a word…", text: $text)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                    .submitLabel(.search)
                    .onSubmit {
                        if let word = words.last {
                            submit(word)
                        }
                    }

                Button(action: {
                    if let word = words.last {
                        submit(word)
                    }
                }) {
                    Label("Search", systemImage: "arrow.up")
                        .labelStyle(.iconOnly)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(isSendButtonVisible ? 1 : 0)
                .disabled(!isSendButtonVisible)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

private struct InlineFavoritesToggle: View {
    let word: String
    let rhyme: String

    @Query private var allFavorites: [FavoriteRhyme]
    @Environment(\.modelContext) private var modelContext

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

        if existing.first != nil {
            for item in existing { modelContext.delete(item) }
        } else {
            modelContext.insert(FavoriteRhyme(word: word, rhyme: rhyme))
        }
        try? modelContext.save()
    }

    var body: some View {
        FavoritesToggle(
            action: toggleFavorite,
            isActivated: isFavorite,
            size: .large
        )
    }
}

private struct LyricAssistantPreview: View {
    @State var text: String = "Hello World"

    var body: some View {
        LyricAssistantView(text: $text)
    }
}

#Preview {
    LyricAssistantPreview()
}
