import SwiftUI

struct WhatsNewFeature {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

struct WhatsNewRelease {
    let version: String
    let features: [WhatsNewFeature]
}

enum WhatsNewContent {
    static let releases: [WhatsNewRelease] = [
        WhatsNewRelease(
            version: "2.0.0",
            features: [
                WhatsNewFeature(
                    icon: "pencil.and.outline",
                    title: "Composition Editor",
                    description: "Write lyrics in a full editor with an inline rhyme assistant — find the perfect rhyme without leaving your flow. Syncs safely across devices via iCloud."
                ),
                WhatsNewFeature(
                    icon: "star.fill",
                    title: "iCloud Favorites",
                    description: "Your favorite rhymes now sync across all your devices with iCloud."
                ),
            ]
        ),
    ]
}
