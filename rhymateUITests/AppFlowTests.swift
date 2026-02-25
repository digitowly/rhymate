import XCTest

/// Comprehensive visual regression tests that walk through every major app flow.
/// Run via `fastlane test_screenshots` — output goes to fastlane/test_screenshots/.
/// Naming: <section>_<index>_<description> so screenshots sort into logical groups.
@MainActor
final class AppFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
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

    // MARK: - Search tab

    func test_search_01_empty() {
        launch()
        snapshot("search_01_empty")
    }

    func test_search_02_keyboard_active() {
        launch()
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 5) { searchField.tap() }
        sleep(1)
        snapshot("search_02_keyboard_active")
    }

    func test_search_03_suggestions() {
        launch()
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else { return }
        searchField.tap()
        guard app.keyboards.firstMatch.waitForExistence(timeout: 5) else { return }
        searchField.typeText("love")
        sleep(2) // wait for suggestion list
        snapshot("search_03_suggestions")
    }

    func test_search_04_results() {
        launch()
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else {
            snapshot("search_04_results")
            return
        }
        searchField.tap()
        guard app.keyboards.firstMatch.waitForExistence(timeout: 5) else {
            snapshot("search_04_results")
            return
        }
        searchField.typeText("love")
        app.keyboards.buttons["search"].tap()
        sleep(3)
        snapshot("search_04_results")
    }

    func test_search_06_no_results() {
        launch()
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else { return }
        searchField.tap()
        guard app.keyboards.firstMatch.waitForExistence(timeout: 5) else { return }
        searchField.typeText("xz") // 2 chars — triggers noResults immediately (< 3 char minimum)
        sleep(2)
        snapshot("search_06_no_results")
    }

    func test_search_07_rhyme_detail() {
        launch()
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else { return }
        searchField.tap()
        guard app.keyboards.firstMatch.waitForExistence(timeout: 5) else { return }
        searchField.typeText("love")
        app.keyboards.buttons["search"].tap()
        sleep(3) // wait for RhymesView + results grid to load
        // Tap the first rhyme button in the scroll view to open RhymeDetailView
        let firstRhyme = app.scrollViews.buttons.firstMatch
        if firstRhyme.waitForExistence(timeout: 3) {
            firstRhyme.tap()
            sleep(2)
        }
        snapshot("search_07_rhyme_detail")
    }

    func test_search_08_history() {
        launch()
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else { return }
        searchField.tap()
        guard app.keyboards.firstMatch.waitForExistence(timeout: 5) else { return }
        searchField.typeText("love")
        app.keyboards.buttons["search"].tap()
        sleep(2) // wait for RhymesView to push
        // Navigate back — RhymesView.onDisappear stores "love" in history
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)
        // Cancel active search to return to home screen (clears input, reveals recent searches)
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
            sleep(1)
        }
        // Tap "Show all" to navigate to SearchHistoryScreen
        let showAllLink = app.links["Show all"]
        if showAllLink.waitForExistence(timeout: 2) {
            showAllLink.tap()
        } else {
            let showAllButton = app.buttons.matching(NSPredicate(format: "label == 'Show all'")).firstMatch
            if showAllButton.waitForExistence(timeout: 2) { showAllButton.tap() }
        }
        sleep(1)
        snapshot("search_08_history")
    }

    func test_search_05_about() {
        launch()
        // The About link lives in the home screen (search history / favorites present),
        // but is also reachable when the search field is empty via the ScrollView.
        // Navigate by scrolling to the About link and tapping it.
        let aboutLink = app.links["About"]
        if !aboutLink.waitForExistence(timeout: 3) {
            // If not visible yet, look for the label version
            let aboutButton = app.buttons.matching(NSPredicate(format: "label == 'About'")).firstMatch
            if aboutButton.waitForExistence(timeout: 3) { aboutButton.tap() }
        } else {
            aboutLink.tap()
        }
        sleep(1)
        snapshot("search_05_about")
    }

    // MARK: - Projects tab — collections

    func test_projects_01_collections_empty() {
        launch()
        navigateToProjects()
        snapshot("projects_01_collections_empty")
    }

    func test_projects_02_collections_list() {
        launch()
        navigateToProjects()
        // Collections are seeded by the app on launch; wait for them to appear.
        _ = app.cells.matching(identifier: "collection-Desert Sessions").firstMatch
            .waitForExistence(timeout: 5)
        sleep(1)
        snapshot("projects_02_collections_list")
    }

    // MARK: - Projects tab — compositions

    func test_projects_03_composition_list_empty() {
        launch()
        navigateToProjects()
        // Create a collection but do NOT seed lyrics, so composition list is empty.
        // Temporarily: create collection without -seedComposerLyrics... but we always
        // pass it above. The list starts empty until the seeder runs on Desert Sessions.
        // Create a different collection name to get a guaranteed empty list.
        ensureCollectionExists(named: "Road Trip")
        // Navigate into it (iPhone) or select it (iPad)
        let cell = app.cells.matching(identifier: "collection-Road Trip").firstMatch
        if cell.waitForExistence(timeout: 3) && cell.isHittable { cell.tap() }
        sleep(1)
        snapshot("projects_03_composition_list_empty")
    }

    func test_projects_04_composition_list() {
        launch()
        navigateToProjects()
        ensureCollectionExists(named: "Desert Sessions")
        _ = app.cells
            .matching(NSPredicate(format: "identifier BEGINSWITH 'composition-'"))
            .firstMatch
            .waitForExistence(timeout: 8)
        sleep(1)
        snapshot("projects_04_composition_list")
    }

    // MARK: - Projects tab — editor

    func test_projects_05_editor() {
        launch(extraArgs: ["-openFirstComposition", "-detailOnlyForSnapshot"])
        navigateToProjects()
        ensureCollectionExists(named: "Desert Sessions")
        _ = app.textViews["compose-text-view"].waitForExistence(timeout: 10)
        sleep(1)
        snapshot("projects_05_editor")
    }

    func test_projects_06_lyric_assistant() {
        launch(extraArgs: ["-openFirstComposition", "-openAssistantForSnapshot", "-detailOnlyForSnapshot"])
        navigateToProjects()
        ensureCollectionExists(named: "Desert Sessions")
        _ = app.textViews["compose-text-view"].waitForExistence(timeout: 10)
        sleep(6) // 1.5s open delay + network rhyme fetch
        snapshot("projects_06_lyric_assistant")
    }

    func test_projects_07_collection_edit() {
        launch()
        navigateToProjects()
        _ = app.cells.matching(identifier: "collection-Desert Sessions").firstMatch
            .waitForExistence(timeout: 5)
        // Enter edit mode to show rename/delete options on collection rows
        let editButton = app.navigationBars.buttons["Edit"]
        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()
            sleep(1)
        }
        snapshot("projects_07_collection_edit")
    }

    func test_projects_08_move_view() {
        launch(extraArgs: ["-openFirstComposition"])
        navigateToProjects()
        ensureCollectionExists(named: "Desert Sessions")
        _ = app.textViews["compose-text-view"].waitForExistence(timeout: 10)
        sleep(1)
        // Tap the ellipsis / More menu in the editor navigation bar
        let moreButton = app.navigationBars.buttons.matching(
            NSPredicate(format: "label == 'More' OR label == 'ellipsis'")
        ).firstMatch
        if moreButton.waitForExistence(timeout: 3) {
            moreButton.tap()
            sleep(1)
            let moveButton = app.buttons["Move"]
            if moveButton.waitForExistence(timeout: 2) {
                moveButton.tap()
                sleep(1)
            }
        }
        snapshot("projects_08_move_view")
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
        } else { return }

        let nameField = app.alerts.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.typeText(name)
            app.alerts.buttons["Save"].tap()
            sleep(1)
        }
    }
}
