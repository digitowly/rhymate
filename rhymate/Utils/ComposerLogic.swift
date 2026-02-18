import UIKit

enum ComposerLogic {

    // MARK: - Lyric Assistant

    static func words(in text: String) -> [String] {
        text.split(separator: " ").map { Formatter.normalize(String($0)) }
    }

    static func isSendButtonVisible(words: [String], currentSearchText: String) -> Bool {
        guard let lastWord = words.last else { return false }
        return lastWord != currentSearchText
    }

    // MARK: - Drag Gesture

    static func resistedDragOffset(translation: CGFloat) -> CGFloat {
        translation > 0 ? translation : translation * 0.15
    }

    static func shouldDismiss(translation: CGFloat, threshold: CGFloat = 100) -> Bool {
        translation > threshold
    }

    // MARK: - Collection Reordering

    static func applyMove<T>(
        _ items: inout [T],
        from source: IndexSet,
        to destination: Int,
        setSortOrder: (T, Int) -> Void
    ) {
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            setSortOrder(item, index)
        }
    }

    // MARK: - Text Trait Toggle

    static func toggleTrait(
        _ trait: UIFontDescriptor.SymbolicTraits,
        in attributedString: NSAttributedString,
        over range: NSRange
    ) -> NSAttributedString {
        guard range.length > 0 else { return attributedString }

        let mutable = NSMutableAttributedString(attributedString: attributedString)

        mutable.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            if let font = value as? UIFont {
                var traits = font.fontDescriptor.symbolicTraits
                if traits.contains(trait) {
                    traits.remove(trait)
                } else {
                    traits.insert(trait)
                }
                if let newDescriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                    let updatedFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
                    mutable.addAttribute(.font, value: updatedFont, range: subrange)
                }
            }
        }

        return mutable
    }
}
