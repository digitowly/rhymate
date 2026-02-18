
enum LyricType {
    case word
    case phrase
    case none
    
    static func from(_ text: String) -> LyricType {
        let textFragments = text.split(separator: " ");
        return switch textFragments.count {
        case 0: .none
        case 1: .word
        default: .phrase
        }
    }
}
