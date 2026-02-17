import Foundation
import SwiftData

@Model
class FavoriteRhyme {
    var word: String = ""
    var rhyme: String = ""

    init(word: String, rhyme: String) {
        self.word = word
        self.rhyme = rhyme
    }
}
