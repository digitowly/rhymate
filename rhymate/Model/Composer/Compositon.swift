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

    var displayTitle: String {
        let firstLine = content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        guard let firstLine, !firstLine.isEmpty else { return "New Song" }
        return firstLine
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
