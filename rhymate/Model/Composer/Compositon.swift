import SwiftData
import Foundation

@Model
class Composition {

    var id: UUID = UUID()

    var title: String = ""
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var chordsData: Data?

    var collection: CompositionCollection?

    @Transient
    var chords: [ChordPlacement] {
        get {
            guard let data = chordsData else { return [] }
            return (try? JSONDecoder().decode([ChordPlacement].self, from: data)) ?? []
        }
        set {
            chordsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        title: String = "",
        content: String = "",
        collection: CompositionCollection? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = .now
        self.updatedAt = .now
        self.collection = collection
    }
}
