import SwiftUI
import SwiftData

// MARK: - Snapshot data seeding (Debug only)
//
// Used by fastlane snapshot to pre-populate the composer with sample lyrics.
// In Release builds the modifier is a no-op and all #if DEBUG code is stripped.

#if DEBUG
private struct SnapshotCollectionSeeder: ViewModifier {
    let collections: [CompositionCollection]
    @Environment(\.modelContext) private var modelContext

    func body(content: Content) -> some View {
        content.onAppear(perform: seed)
    }

    private func seed() {
        guard ProcessInfo.processInfo.arguments.contains("-seedComposerLyrics"),
              collections.isEmpty else { return }
        let names = ["Desert Sessions", "Road Trip", "Mountain Jams", "Open Sky", "Fuzz Therapy"]
        for (index, name) in names.enumerated() {
            modelContext.insert(CompositionCollection(name: name, sortOrder: index))
        }
        try? modelContext.save()
    }
}

private struct SnapshotCompositionSeeder: ViewModifier {
    let collection: CompositionCollection?
    let compositions: [Composition]
    @Environment(\.modelContext) private var modelContext

    func body(content: Content) -> some View {
        content
            .onAppear(perform: seed)
            .onChange(of: collection?.id) { seed() }
    }

    private func seed() {
        guard ProcessInfo.processInfo.arguments.contains("-seedComposerLyrics"),
              let collection,
              collection.name == "Desert Sessions",
              compositions.isEmpty else { return }

        let songs: [(content: String, daysAgo: Double)] = [
            ("""
            # Open Road
            Wind in my hair and sun on my face
            Nothing ahead but infinite space
            Engine humming, asphalt black
            No reason stopping, no looking back

            Miles of highway, painted white
            Desert calling through the night
            Open road beneath my wheels
            Nothing beats the way this feels
            """, 1),

            ("""
            # Canyon Walls
            Red rock rising to the sky
            Golden eagles soaring high
            Canyon walls of ancient stone
            Out here I am never alone

            Echo bouncing, riff returns
            Mesa glowing as the day burns
            Sand beneath my dusty boots
            Music running to its roots
            """, 3),

            ("""
            # Mountain Echo
            Riff ascending through the pass
            Morning light on frosted glass
            Mountain echo, stone and snow
            Nowhere else I would rather go

            Summit calling, clouds below
            Feel the wind begin to blow
            High above the valley floor
            Always room for one note more
            """, 5),

            ("""
            # Star Driver
            Steering by the southern cross
            No map needed, never lost
            Star driver on the open plain
            Every night I ride again

            Milky Way above my head
            Wide awake and full of wonder instead
            Cosmic highway, no speed limit
            Best when there is no ceiling in it
            """, 8),

            ("""
            # Dust and Wind
            Dust rising from the canyon floor
            Wind arriving at my door
            Tumbleweed across the lane
            Desert songs inside my brain

            Fuzz guitar and open chord
            Every note its own reward
            Dust and wind and afternoon
            Humming like an old folk tune
            """, 11),

            ("""
            # Iron Horse
            Steel machine beneath my hands
            Rolling through the desert lands
            Chrome and gravel, sun to spare
            Engine singing through the air

            Long white road and golden sun
            Playing music just for fun
            Iron horse won't let me down
            Miles away from any town
            """, 14),

            ("""
            # Amber Sky
            Sunset painting amber wide
            Nowhere else I want to ride
            Amp turned up and window down
            Leaving every care in town

            Strings vibrating in the heat
            Every measure, every beat
            Amber sky says come on home
            But first one more mile to roam
            """, 18),

            ("""
            # Valley Floor
            Down below the rocky ridge
            Crossing every canyon bridge
            Valley floor of ancient stone
            Somewhere I have always known

            Bass line rolling, drums in time
            Every canyon, every climb
            Valley floor beneath my feet
            Music makes the journey sweet
            """, 22),
        ]

        let now = Date.now
        for (content, daysAgo) in songs {
            let composition = Composition(
                content: content,
                collection: collection
            )
            composition.updatedAt = now - daysAgo * 86_400
            modelContext.insert(composition)
        }
        try? modelContext.save()
    }
}
#endif

extension View {
    func snapshotCollectionSeeding(collections: [CompositionCollection]) -> some View {
        #if DEBUG
        modifier(SnapshotCollectionSeeder(collections: collections))
        #else
        self
        #endif
    }

    func snapshotCompositionSeeding(collection: CompositionCollection?, compositions: [Composition]) -> some View {
        #if DEBUG
        modifier(SnapshotCompositionSeeder(collection: collection, compositions: compositions))
        #else
        self
        #endif
    }
}
