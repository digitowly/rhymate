import SwiftData
import Foundation

@Model
class Composition {

    var id: UUID = UUID()

    var title: String = ""
    var contentData: Data = Data()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var collection: CompositionCollection?

    @Transient
    var content: NSAttributedString {
        get {
            (try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSAttributedString.self,
                from: contentData
            )) ?? NSAttributedString(string: "")
        }
        set {
            contentData =
                (try? NSKeyedArchiver.archivedData(
                    withRootObject: newValue,
                    requiringSecureCoding: false
                )) ?? Data()
        }
    }

    init(
        title: String = "",
        content: NSAttributedString? = nil,
        collection: CompositionCollection? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.contentData =
            (try? NSKeyedArchiver.archivedData(
                withRootObject: content ?? NSAttributedString(),
                requiringSecureCoding: false
            )) ?? Data()
        self.createdAt = .now
        self.updatedAt = .now
        self.collection = collection
    }
}
