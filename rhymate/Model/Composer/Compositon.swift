import SwiftData
import Foundation

@Model
class Composition {

    var id: UUID = UUID()

    var title: String = ""
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var collection: CompositionCollection?

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
