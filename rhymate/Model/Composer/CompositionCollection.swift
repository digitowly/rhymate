import SwiftData
import Foundation

@Model
class CompositionCollection {

    var name: String = ""
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade)
    var compositions: [Composition]? = []

    init(name: String = "", sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}
