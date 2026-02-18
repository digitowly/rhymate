import Foundation

internal struct DatamuseFetcher {
    
    private let rhymesStorage = RhymesStorage()
    private let fetcher: Fetcher
    
    let baseUrlWords = DATAMUSE_API_URL.appendingPathComponent("/words")
    let baseUrlSuggestions = DATAMUSE_API_URL.appendingPathComponent("/sug")
    
    init(
        configuration: URLSessionConfiguration = URLSessionConfiguration.default
    ) {
        self.fetcher = Fetcher(configuration: configuration)
    }
    
    /// Fetch Ryhmes from Datamuse API (https://api.datamuse.com/words?rel_rhy=word)
    func getRhymes(forWord: String) async throws -> [DatamuseRhyme] {
        let word = Formatter.normalize(forWord)
        
        // prefer local store if word already exists in UserDefaults
        if let localResult = rhymesStorage.get(word: word), !localResult.isEmpty {
            return localResult
        }
        
        // fetch data from datamuse
        var urlComponents = URLComponents(string: baseUrlWords.absoluteString)!
        urlComponents.queryItems = [
            // defines the query term to rhyme
            URLQueryItem(name: "rel_rhy", value: word),
            
            // defines the vocabulary to use (es -> spanish, enwiki -> english)
            URLQueryItem(name: "v", value: "enwiki"),
        ]
        let url = urlComponents.url!
        if let rhymesResponse: [DatamuseRhyme] = try await fetcher.get(url) {
            let sortedRhymeResponse = rhymesResponse.sorted{
                $0.score ?? 0 > $1.score ?? 0
            }
            // store response in UserDefaults
            try rhymesStorage.mutate(.add, key: word, sortedRhymeResponse)
            return sortedRhymeResponse
        }
        return []
    }
    
    /// Fetch rhyme suggestions from Datamuse API (https://api.datamuse.com/sug?s=word)
    func getSuggestions(forWord: String) async throws -> [DatamuseSuggestion] {
        let word = Formatter.normalize(forWord)

        var urlComponents = URLComponents(string: baseUrlSuggestions.absoluteString)!
        urlComponents.queryItems = [
            // defines the search string
            URLQueryItem(name: "s", value: word),
        ]
        let url = urlComponents.url!
        if let suggestions: [DatamuseSuggestion] = try await fetcher.get(url) {
            return suggestions
        }
        return []
    }
}
