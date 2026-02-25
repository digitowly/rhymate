import SwiftUI
import SwiftData

@main
struct rhymateApp: App {
    let container: ModelContainer

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-inMemoryStore") {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(
                for: Composition.self, CompositionCollection.self, FavoriteRhyme.self,
                configurations: config
            )
            return
        }
        #endif

        let config = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.demonyze.rhymate")
        )
        do {
            container = try ModelContainer(
                for: Composition.self, CompositionCollection.self, FavoriteRhyme.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

        FavoritesMigrator(container: container).migrateFromUserDefaults()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
