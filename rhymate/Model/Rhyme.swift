struct RhymeItem: Identifiable {
    var id: String{word + rhyme}
    var word: String
    var rhyme: String
}

struct RhymeSuggestion: Identifiable, Equatable {
    var id: String { text }
    var text: String
    var isAI: Bool
}
