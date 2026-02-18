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

        let existingFavorites = (try? context.fetch(FetchDescriptor<FavoriteRhyme>())) ?? []
        let existingKeys = Set(existingFavorites.map { "\($0.word):\($0.rhyme)" })

        for (_, entry) in legacy {
            let word = Formatter.normalize(entry.word)
            for rhyme in entry.rhymes where !rhyme.isEmpty {
                let key = "\(word):\(rhyme)"
                guard !existingKeys.contains(key) else { continue }
                context.insert(FavoriteRhyme(word: word, rhyme: rhyme))
            }
        }

        do {
            try context.save()
            defaults.removeObject(forKey: key)
        } catch {
            print("Favorites migration failed, will retry next launch: \(error)")
        }
    }
}

struct LegacyRhymeWithFavorites: Codable {
    let word: String
    var rhymes: [String]
}
