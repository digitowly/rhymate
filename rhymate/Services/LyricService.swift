
struct LyricService {
    private let datamuseClient = DatamuseFetcher()

    func getSuggestions(forText text: String, _ type: LyricType) async -> Result<[RhymeSuggestion], SearchError> {
        switch type {
        case .word:   return await getRhymesForWord(text)
        case .phrase: return await getRhymesForPhrase(text)
        case .none:   return .failure(.noResults)
        }
    }

    private func getRhymesForWord(_ word: String) async -> Result<[RhymeSuggestion], SearchError> {
        do {
            let datamuseRhymes = try await datamuseClient.getRhymes(forWord: word)
            var results = datamuseRhymes.map { RhymeSuggestion(text: $0.word, isAI: false) }
            if results.count < 10 && AIFeatures.isEnabled {
                let aiExtras = await foundationModelSupplement(word: word, excluding: results.map(\.text))
                results += aiExtras.map { RhymeSuggestion(text: $0, isAI: true) }
            }
            return results.isEmpty ? .failure(.noResults) : .success(results)
        } catch {
            return .failure(SearchError.from(error))
        }
    }

    private func getRhymesForPhrase(_ phrase: String) async -> Result<[RhymeSuggestion], SearchError> {
        guard let lastWord = phrase.split(separator: " ").last.map(String.init) else {
            return .failure(.noResults)
        }

        let datamuseWords: [String] = (try? await datamuseClient.getRhymes(forWord: lastWord).map(\.word)) ?? []

        #if canImport(FoundationModels)
        if AIFeatures.isEnabled, #available(iOS 26.0, macOS 26.0, *), FoundationModelRhymer.isAvailable {
            let aiPhrases = (try? await FoundationModelRhymer().lyricEndings(rhymingWith: lastWord)) ?? []
            if !aiPhrases.isEmpty {
                return .success(aiPhrases.map { RhymeSuggestion(text: $0, isAI: true) })
            }
        }
        #endif

        // Fallback: show raw Datamuse words when AI is unavailable or returns nothing.
        return datamuseWords.isEmpty
            ? .failure(.noResults)
            : .success(datamuseWords.map { RhymeSuggestion(text: $0, isAI: false) })
    }

    func getSuggestedLines(forPhrase phrase: String) async -> Result<[String], SearchError> {
        guard AIFeatures.isEnabled else { return .failure(.noResults) }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), FoundationModelRhymer.isAvailable {
            do {
                let lines = try await FoundationModelRhymer().lyricSuggestions(forLine: phrase)
                if !lines.isEmpty { return .success(lines) }
            } catch {}
        }
        #endif
        return .failure(.noResults)
    }

    private func foundationModelSupplement(word: String, excluding: [String]) async -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), FoundationModelRhymer.isAvailable {
            return (try? await FoundationModelRhymer().supplement(word: word, excluding: excluding)) ?? []
        }
        #endif
        return []
    }
}
