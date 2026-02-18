import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @AppStorage("whatsNewLastSeenVersion") private var lastSeenVersion = ""
    @State private var showWhatsNew = false

    @State private var selectedComposition: Composition?
    @State private var selectedCollection: CompositionCollection?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        TabView {
            NavigationStack {
                SearchScreen()
            }.tabItem {
                Image(systemName: "character.book.closed.fill")
                Text("Rhymes")
            }

            NavigationSplitView(columnVisibility: $columnVisibility) {
                CompositionCollectionListView(selectedCollection: $selectedCollection)
            } content: {
                if let collection = selectedCollection {
                    CompositionListView(
                        selectedCollection: collection,
                        selectedComposition: $selectedComposition
                    )
                } else {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Project Selected",
                        description: "Select a project from the sidebar or create a new one to get started."
                    )
                }
            } detail: {
                if let composition = selectedComposition {
                    CompositionView(
                        composition: composition,
                        columnVisibility: $columnVisibility
                    )
                } else {
                    EmptyStateView(
                        icon: "music.note.list",
                        title: "No Composition Selected",
                        description: "Select a composition to start writing."
                    )
                }
            }.tabItem {
                Image(systemName: "music.pages.fill")
                Text("Projects")
            }
        }
        .onChange(of: selectedCollection) {
            if let collection = selectedCollection {
                if horizontalSizeClass == .regular {
                    if selectedComposition?.collection?.id != collection.id {
                        selectedComposition = collection.compositions?
                            .sorted(by: { $0.updatedAt > $1.updatedAt })
                            .first
                    }
                    columnVisibility = .doubleColumn
                } else {
                    selectedComposition = nil
                }
            }
        }
        .onChange(of: selectedComposition) {}
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
