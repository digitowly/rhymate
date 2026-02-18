import XCTest
import SwiftData
@testable import rhymate

final class FavoritesMigratorTests: XCTestCase {
    var container: ModelContainer!
    let testKey = "favoriteRhymes"

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: FavoriteRhyme.self,
            configurations: config
        )
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: testKey)
        container = nil
    }

    // MARK: - Migration

    func testMigratesLegacyFavorites() throws {
        let legacyData: [String: LegacyRhymeWithFavorites] = [
            "test": LegacyRhymeWithFavorites(word: "test", rhymes: ["best", "chest"]),
            "flow": LegacyRhymeWithFavorites(word: "flow", rhymes: ["glow"])
        ]
        let jsonData = try JSONEncoder().encode(legacyData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        UserDefaults.standard.set(jsonString, forKey: testKey)

        FavoritesMigrator(container: container).migrateFromUserDefaults()

        let context = ModelContext(container)
        let results = try context.fetch(FetchDescriptor<FavoriteRhyme>())

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.contains { $0.word == "test" && $0.rhyme == "best" })
        XCTAssertTrue(results.contains { $0.word == "test" && $0.rhyme == "chest" })
        XCTAssertTrue(results.contains { $0.word == "flow" && $0.rhyme == "glow" })
    }

    func testMigrationRemovesUserDefaultsKey() throws {
        let legacyData: [String: LegacyRhymeWithFavorites] = [
            "test": LegacyRhymeWithFavorites(word: "test", rhymes: ["best"])
        ]
        let jsonData = try JSONEncoder().encode(legacyData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        UserDefaults.standard.set(jsonString, forKey: testKey)

        FavoritesMigrator(container: container).migrateFromUserDefaults()

        XCTAssertNil(UserDefaults.standard.string(forKey: testKey))
    }

    func testMigrationNormalizesWords() throws {
        let legacyData: [String: LegacyRhymeWithFavorites] = [
            "Test": LegacyRhymeWithFavorites(word: "Test", rhymes: ["best"]),
            " FLOW ": LegacyRhymeWithFavorites(word: " FLOW ", rhymes: ["glow"])
        ]
        let jsonData = try JSONEncoder().encode(legacyData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        UserDefaults.standard.set(jsonString, forKey: testKey)

        FavoritesMigrator(container: container).migrateFromUserDefaults()

        let context = ModelContext(container)
        let results = try context.fetch(FetchDescriptor<FavoriteRhyme>())

        XCTAssertTrue(results.allSatisfy { $0.word == Formatter.normalize($0.word) })
        XCTAssertTrue(results.contains { $0.word == "test" })
        XCTAssertTrue(results.contains { $0.word == "flow" })
    }

    func testNoOpWhenNoLegacyData() throws {
        FavoritesMigrator(container: container).migrateFromUserDefaults()

        let context = ModelContext(container)
        let results = try context.fetch(FetchDescriptor<FavoriteRhyme>())
        XCTAssertTrue(results.isEmpty)
    }

    func testSkipsEmptyRhymes() throws {
        let legacyData: [String: LegacyRhymeWithFavorites] = [
            "test": LegacyRhymeWithFavorites(word: "test", rhymes: ["best", "", "chest"])
        ]
        let jsonData = try JSONEncoder().encode(legacyData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        UserDefaults.standard.set(jsonString, forKey: testKey)

        FavoritesMigrator(container: container).migrateFromUserDefaults()

        let context = ModelContext(container)
        let results = try context.fetch(FetchDescriptor<FavoriteRhyme>())
        XCTAssertEqual(results.count, 2)
        XCTAssertFalse(results.contains { $0.rhyme.isEmpty })
    }

    func testMigrationIsIdempotent() throws {
        let legacyData: [String: LegacyRhymeWithFavorites] = [
            "test": LegacyRhymeWithFavorites(word: "test", rhymes: ["best"])
        ]
        let jsonData = try JSONEncoder().encode(legacyData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        UserDefaults.standard.set(jsonString, forKey: testKey)

        // First migration
        FavoritesMigrator(container: container).migrateFromUserDefaults()

        // Simulate crash before removeObject by re-setting the key
        UserDefaults.standard.set(jsonString, forKey: testKey)

        // Second migration
        FavoritesMigrator(container: container).migrateFromUserDefaults()

        let context = ModelContext(container)
        let results = try context.fetch(FetchDescriptor<FavoriteRhyme>())
        // Unique constraint should prevent duplicates
        XCTAssertEqual(results.count, 1)
    }
}
