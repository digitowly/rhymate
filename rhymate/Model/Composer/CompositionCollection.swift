import SwiftData
import Foundation

@Model
class CompositionCollection {

    var name: String = ""

    @Relationship(deleteRule: .cascade)
    var compositions: [Composition]? = []

    init(name: String = "") {
        self.name = name
    }
}
