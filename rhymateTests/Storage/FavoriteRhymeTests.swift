import XCTest
import SwiftData
@testable import rhymate

final class FavoriteRhymeTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: FavoriteRhyme.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Basic CRUD

    func testInsertAndFetch() throws {
        context.insert(FavoriteRhyme(word: "test", rhyme: "best"))
        try context.save()

        let descriptor = FetchDescriptor<FavoriteRhyme>()
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.word, "test")
        XCTAssertEqual(results.first?.rhyme, "best")
    }

    func testDelete() throws {
        let favorite = FavoriteRhyme(word: "test", rhyme: "best")
        context.insert(favorite)
        try context.save()

        context.delete(favorite)
        try context.save()

        let descriptor = FetchDescriptor<FavoriteRhyme>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 0)
    }

    func testMultipleFavoritesForSameWord() throws {
        context.insert(FavoriteRhyme(word: "test", rhyme: "best"))
        context.insert(FavoriteRhyme(word: "test", rhyme: "chest"))
        context.insert(FavoriteRhyme(word: "test", rhyme: "west"))
        try context.save()

        let descriptor = FetchDescriptor<FavoriteRhyme>(
            predicate: #Predicate { $0.word == "test" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 3)
    }

    // MARK: - Uniqueness

    func testDifferentPairsAreNotDuplicates() throws {
        context.insert(FavoriteRhyme(word: "test", rhyme: "best"))
        context.insert(FavoriteRhyme(word: "test", rhyme: "chest"))
        context.insert(FavoriteRhyme(word: "rest", rhyme: "best"))
        try context.save()

        let descriptor = FetchDescriptor<FavoriteRhyme>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 3)
    }

    // MARK: - Toggle Logic

    func testToggleFavoriteAdd() throws {
        let allFavorites = try context.fetch(FetchDescriptor<FavoriteRhyme>())
        XCTAssertTrue(allFavorites.isEmpty)

        // Simulate add
        let word = "test"
        let rhyme = "best"
        if !allFavorites.contains(where: { $0.word == word && $0.rhyme == rhyme }) {
            context.insert(FavoriteRhyme(word: word, rhyme: rhyme))
        }
        try context.save()

        let results = try context.fetch(FetchDescriptor<FavoriteRhyme>())
        XCTAssertEqual(results.count, 1)
    }

    func testToggleFavoriteRemove() throws {
        let favorite = FavoriteRhyme(word: "test", rhyme: "best")
        context.insert(favorite)
        try context.save()

        // Simulate remove
        let allFavorites = try context.fetch(FetchDescriptor<FavoriteRhyme>())
        if let existing = allFavorites.first(where: { $0.word == "test" && $0.rhyme == "best" }) {
            context.delete(existing)
        }
        try context.save()

        let results = try context.fetch(FetchDescriptor<FavoriteRhyme>())
        XCTAssertTrue(results.isEmpty)
    }
}
