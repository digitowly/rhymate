
enum SearchError: Error {
    case noResults
    case generic
    case network
    
    static func from(_ error: Error) -> SearchError {
        print(error)
        switch error._code {
        case -1009:
            return .network
        default:
            return .generic
        }
    }
}
