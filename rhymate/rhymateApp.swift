import SwiftUI
import SwiftData

@main
struct rhymateApp: App {
    let container: ModelContainer

    init() {
        let config = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.demonyze.rhymate")
        )
        do {
            container = try ModelContainer(
                for: Composition.self, CompositionCollection.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
