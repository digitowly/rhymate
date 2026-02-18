import XCTest
@testable import rhymate

final class ComposerLogicTests: XCTestCase {

    // MARK: - words(in:)

    func testWordsSingleWord() {
        XCTAssertEqual(ComposerLogic.words(in: "hello"), ["hello"])
    }

    func testWordsMultipleWords() {
        XCTAssertEqual(ComposerLogic.words(in: "hello world foo"), ["hello", "world", "foo"])
    }

    func testWordsPunctuationStripped() {
        XCTAssertEqual(ComposerLogic.words(in: "hello, world!"), ["hello", "world"])
    }

    func testWordsEmptyString() {
        XCTAssertEqual(ComposerLogic.words(in: ""), [])
    }

    func testWordsWhitespaceOnly() {
        XCTAssertEqual(ComposerLogic.words(in: "   "), [])
    }

    // MARK: - isSendButtonVisible(words:currentSearchText:)

    func testSendButtonVisibleEmptyWords() {
        XCTAssertFalse(ComposerLogic.isSendButtonVisible(words: [], currentSearchText: ""))
    }

    func testSendButtonVisibleLastWordMatchesSearch() {
        XCTAssertFalse(ComposerLogic.isSendButtonVisible(words: ["hello"], currentSearchText: "hello"))
    }

    func testSendButtonVisibleLastWordDiffersFromSearch() {
        XCTAssertTrue(ComposerLogic.isSendButtonVisible(words: ["hello", "world"], currentSearchText: "hello"))
    }

    // MARK: - resistedDragOffset(translation:)

    func testResistedDragOffsetPositivePassthrough() {
        XCTAssertEqual(ComposerLogic.resistedDragOffset(translation: 50), 50)
    }

    func testResistedDragOffsetNegativeDampened() {
        XCTAssertEqual(ComposerLogic.resistedDragOffset(translation: -100), -100 * 0.15, accuracy: 0.001)
    }

    func testResistedDragOffsetZero() {
        XCTAssertEqual(ComposerLogic.resistedDragOffset(translation: 0), 0)
    }

    // MARK: - shouldDismiss(translation:threshold:)

    func testShouldDismissBelowThreshold() {
        XCTAssertFalse(ComposerLogic.shouldDismiss(translation: 50))
    }

    func testShouldDismissAtThresholdStrictGreaterThan() {
        XCTAssertFalse(ComposerLogic.shouldDismiss(translation: 100))
    }

    func testShouldDismissAboveThreshold() {
        XCTAssertTrue(ComposerLogic.shouldDismiss(translation: 150))
    }

    func testShouldDismissNegativeTranslation() {
        XCTAssertFalse(ComposerLogic.shouldDismiss(translation: -50))
    }

    func testShouldDismissCustomThreshold() {
        XCTAssertTrue(ComposerLogic.shouldDismiss(translation: 60, threshold: 50))
        XCTAssertFalse(ComposerLogic.shouldDismiss(translation: 40, threshold: 50))
    }

    // MARK: - applyMove(_:from:to:setSortOrder:)

    private class FakeItem {
        let name: String
        var sortOrder: Int
        init(name: String, sortOrder: Int) {
            self.name = name
            self.sortOrder = sortOrder
        }
    }

    func testApplyMoveMoveDown() {
        var items = [
            FakeItem(name: "A", sortOrder: 0),
            FakeItem(name: "B", sortOrder: 1),
            FakeItem(name: "C", sortOrder: 2),
        ]
        ComposerLogic.applyMove(&items, from: IndexSet(integer: 0), to: 3) { $0.sortOrder = $1 }
        XCTAssertEqual(items.map(\.name), ["B", "C", "A"])
        XCTAssertEqual(items.map(\.sortOrder), [0, 1, 2])
    }

    func testApplyMoveMoveUp() {
        var items = [
            FakeItem(name: "A", sortOrder: 0),
            FakeItem(name: "B", sortOrder: 1),
            FakeItem(name: "C", sortOrder: 2),
        ]
        ComposerLogic.applyMove(&items, from: IndexSet(integer: 2), to: 0) { $0.sortOrder = $1 }
        XCTAssertEqual(items.map(\.name), ["C", "A", "B"])
        XCTAssertEqual(items.map(\.sortOrder), [0, 1, 2])
    }

    func testApplyMoveContiguousSortOrder() {
        var items = [
            FakeItem(name: "A", sortOrder: 5),
            FakeItem(name: "B", sortOrder: 10),
            FakeItem(name: "C", sortOrder: 20),
        ]
        ComposerLogic.applyMove(&items, from: IndexSet(integer: 0), to: 2) { $0.sortOrder = $1 }
        XCTAssertEqual(items.map(\.sortOrder), [0, 1, 2])
    }

    func testApplyMoveSingleItem() {
        var items = [FakeItem(name: "A", sortOrder: 0)]
        ComposerLogic.applyMove(&items, from: IndexSet(integer: 0), to: 1) { $0.sortOrder = $1 }
        XCTAssertEqual(items.map(\.name), ["A"])
        XCTAssertEqual(items.map(\.sortOrder), [0])
    }

    // MARK: - toggleTrait(_:in:over:)

    private func plainString(_ text: String, size: CGFloat = 17) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: size)])
    }

    func testToggleTraitBoldOn() {
        let input = plainString("hello")
        let result = ComposerLogic.toggleTrait(.traitBold, in: input, over: NSRange(location: 0, length: 5))
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    func testToggleTraitBoldOff() {
        let boldFont = UIFont.boldSystemFont(ofSize: 17)
        let input = NSAttributedString(string: "hello", attributes: [.font: boldFont])
        let result = ComposerLogic.toggleTrait(.traitBold, in: input, over: NSRange(location: 0, length: 5))
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertFalse(font!.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    func testToggleTraitItalicOn() {
        let input = plainString("hello")
        let result = ComposerLogic.toggleTrait(.traitItalic, in: input, over: NSRange(location: 0, length: 5))
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    func testToggleTraitItalicOff() {
        let descriptor = UIFont.systemFont(ofSize: 17).fontDescriptor.withSymbolicTraits(.traitItalic)!
        let italicFont = UIFont(descriptor: descriptor, size: 17)
        let input = NSAttributedString(string: "hello", attributes: [.font: italicFont])
        let result = ComposerLogic.toggleTrait(.traitItalic, in: input, over: NSRange(location: 0, length: 5))
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertFalse(font!.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    func testToggleTraitBoldPreservesItalic() {
        let descriptor = UIFont.systemFont(ofSize: 17).fontDescriptor.withSymbolicTraits(.traitItalic)!
        let italicFont = UIFont(descriptor: descriptor, size: 17)
        let input = NSAttributedString(string: "hello", attributes: [.font: italicFont])
        let result = ComposerLogic.toggleTrait(.traitBold, in: input, over: NSRange(location: 0, length: 5))
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    func testToggleTraitEmptyRangeUnchanged() {
        let input = plainString("hello")
        let result = ComposerLogic.toggleTrait(.traitBold, in: input, over: NSRange(location: 0, length: 0))
        XCTAssertEqual(result, input)
    }

    func testToggleTraitPartialRange() {
        let input = plainString("hello world")
        let result = ComposerLogic.toggleTrait(.traitBold, in: input, over: NSRange(location: 0, length: 5))
        let boldFont = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertTrue(boldFont!.fontDescriptor.symbolicTraits.contains(.traitBold))
        let plainFont = result.attribute(.font, at: 6, effectiveRange: nil) as? UIFont
        XCTAssertFalse(plainFont!.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    func testToggleTraitFontSizePreserved() {
        let input = plainString("hello", size: 24)
        let result = ComposerLogic.toggleTrait(.traitBold, in: input, over: NSRange(location: 0, length: 5))
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.pointSize, 24)
    }
}
