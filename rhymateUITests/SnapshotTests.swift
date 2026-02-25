import XCTest

@MainActor
final class SnapshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "demonyze.rhymate")
    }

    private func launch(extraArgs: [String] = []) {
        app.launchArguments = [
            "-whatsNewLastSeenVersion", "2.0.0",
            "-inMemoryStore",
            "-seedComposerLyrics",
        ] + extraArgs
        setupSnapshot(app)
        app.launch()
    }

    func testRhymeSearch() {
        launch()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()

        guard app.keyboards.firstMatch.waitForExistence(timeout: 5) else {
            snapshot("01_RhymeSearch")
            return
        }

        searchField.typeText("love")
        app.keyboards.buttons["search"].tap()
        sleep(3)
        snapshot("01_RhymeSearch")
    }

    func testProjectOverview() {
        launch()
        navigateToProjects()
        // Collections are seeded by the app on launch; wait for them to appear.
        _ = app.cells.matching(identifier: "collection-Desert Sessions").firstMatch
            .waitForExistence(timeout: 5)
        sleep(1)
        snapshot("02_ProjectOverview")
    }

    func testEditor() {
        launch(extraArgs: ["-openFirstComposition", "-detailOnlyForSnapshot"])
        navigateToProjects()
        ensureCollectionExists(named: "Desert Sessions")
        _ = app.textViews["compose-text-view"].waitForExistence(timeout: 10)
        sleep(1)
        snapshot("03_Editor")
    }

    func testLyricAssistant() {
        launch(extraArgs: ["-openFirstComposition", "-openAssistantForSnapshot", "-detailOnlyForSnapshot"])
        navigateToProjects()
        ensureCollectionExists(named: "Desert Sessions")
        _ = app.textViews["compose-text-view"].waitForExistence(timeout: 10)
        sleep(6)
        snapshot("04_LyricAssistant")
    }

    // MARK: - Helpers

    private func navigateToProjects() {
        app.buttons.matching(NSPredicate(format: "label == 'Projects'")).firstMatch.tap()
        sleep(1)
    }

    private func ensureOnCollectionList() {
        if !app.buttons["New Folder"].waitForExistence(timeout: 2) {
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    private func ensureCollectionExists(named name: String) {
        let existing = app.cells.matching(identifier: "collection-\(name)").firstMatch
        guard !existing.waitForExistence(timeout: 2) else { return }

        let newFolder = app.buttons["New Folder"]
        let createFolder = app.buttons["Create Folder"]
        if newFolder.waitForExistence(timeout: 2) {
            newFolder.tap()
        } else if createFolder.waitForExistence(timeout: 2) {
            createFolder.tap()
        } else {
            return
        }

        let nameField = app.alerts.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.typeText(name)
            app.alerts.buttons["Save"].tap()
            sleep(1)
        }
    }
}
