
struct LyricService {
    let datamuseClient = DatamuseFetcher()
    
    func getSuggestions(forText: String, _ type: LyricType) async -> Result<[String], SearchError> {
        return switch type {
        case .word: await getSuggestionsByWord(forText)
        case .phrase: await getSuggestionsByPhrase(forText)
        case .none: .failure(.noResults)
        }
    }
    
    private func getSuggestionsByWord(_ word: String) async -> Result<[String], SearchError> {
        do {
            let datamuseRhymes = try await datamuseClient.getRhymes(forWord: word)
            if datamuseRhymes.isEmpty {
                return .failure(.noResults)
            }
            
            let rhymes = datamuseRhymes.map{ rhyme -> String in rhyme.word }
            return .success(rhymes)
        } catch {
            return .failure(SearchError.from(error))
        }
    }
    
    private func getSuggestionsByPhrase(_ phrase: String) async -> Result<[String], SearchError> {
        return .failure(.noResults)
    }
}
