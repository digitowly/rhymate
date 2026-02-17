import Foundation
import SwiftData

struct FavoritesMigrator {
    let container: ModelContainer

    func migrateFromUserDefaults() {
        let key = "favoriteRhymes"
        let defaults = UserDefaults.standard

        guard let jsonString = defaults.string(forKey: key),
              let data = jsonString.data(using: .utf8) else { return }

        guard let legacy = try? JSONDecoder().decode([String: LegacyRhymeWithFavorites].self, from: data) else { return }

        let context = ModelContext(container)

        for (_, entry) in legacy {
            let word = Formatter.normalize(entry.word)
            for rhyme in entry.rhymes {
                context.insert(FavoriteRhyme(word: word, rhyme: rhyme))
            }
        }

        try? context.save()
        defaults.removeObject(forKey: key)
    }
}

private struct LegacyRhymeWithFavorites: Decodable {
    let word: String
    var rhymes: [String]
}
