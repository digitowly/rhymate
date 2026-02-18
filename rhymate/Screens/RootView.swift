import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @AppStorage("whatsNewLastSeenVersion") private var lastSeenVersion = ""
    @State private var showWhatsNew = false

    @State private var selectedComposition: Composition?
    @State private var selectedCollection: CompositionCollection?

    var body: some View {
        TabView {
            NavigationStack {
                SearchScreen()
            }.tabItem {
                Image(systemName: "character.book.closed.fill")
                Text("Rhymes")
            }

            NavigationSplitView {
                CompositionCollectionListView(selectedCollection: $selectedCollection)
            } content: {
                if let collection = selectedCollection {
                    CompositionListView(
                        selectedCollection: collection,
                        selectedComposition: $selectedComposition
                    )
                } else {
                    Text("Select something")
                }
            } detail: {
                if let composition = selectedComposition {
                    CompositionView(composition: composition)
                } else {
                    Text("Select a composition")
                }
            }.tabItem {
                Image(systemName: "music.pages.fill")
                Text("Projects")
            }
        }
        .onAppear {
            if let latest = WhatsNewContent.releases.last,
               latest.version != lastSeenVersion {
                showWhatsNew = true
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            if let latest = WhatsNewContent.releases.last {
                WhatsNewView(release: latest)
                    .onDisappear {
                        lastSeenVersion = latest.version
                    }
            }
        }
    }
}

#Preview {
    RootView()
}
