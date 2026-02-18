import XCTest
@testable import rhymate

final class MarkdownConverterTests: XCTestCase {

    // MARK: - toMarkdown

    func testPlainTextRemainsUnchanged() {
        let input = NSAttributedString(string: "hello world")
        XCTAssertEqual(MarkdownConverter.toMarkdown(input), "hello world")
    }

    func testBoldTextWrappedInDoubleAsterisks() {
        let text = "bold"
        let font = UIFont.boldSystemFont(ofSize: 17)
        let input = NSAttributedString(string: text, attributes: [.font: font])
        XCTAssertEqual(MarkdownConverter.toMarkdown(input), "**bold**")
    }

    func testItalicTextWrappedInSingleAsterisks() {
        let text = "italic"
        let descriptor = UIFont.systemFont(ofSize: 17).fontDescriptor.withSymbolicTraits(.traitItalic)!
        let font = UIFont(descriptor: descriptor, size: 17)
        let input = NSAttributedString(string: text, attributes: [.font: font])
        XCTAssertEqual(MarkdownConverter.toMarkdown(input), "*italic*")
    }

    func testBoldItalicTextWrappedInTripleAsterisks() {
        let text = "both"
        let descriptor = UIFont.systemFont(ofSize: 17).fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])!
        let font = UIFont(descriptor: descriptor, size: 17)
        let input = NSAttributedString(string: text, attributes: [.font: font])
        XCTAssertEqual(MarkdownConverter.toMarkdown(input), "***both***")
    }

    func testMixedFormattingProducesCorrectMarkdown() {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "plain "))
        result.append(NSAttributedString(string: "bold", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]))
        result.append(NSAttributedString(string: " end"))

        XCTAssertEqual(MarkdownConverter.toMarkdown(result), "plain **bold** end")
    }

    func testEmptyStringReturnsEmpty() {
        let input = NSAttributedString(string: "")
        XCTAssertEqual(MarkdownConverter.toMarkdown(input), "")
    }

    func testMultipleLinesPreserved() {
        let input = NSAttributedString(string: "line one\nline two\nline three")
        XCTAssertEqual(MarkdownConverter.toMarkdown(input), "line one\nline two\nline three")
    }

    // MARK: - toAttributedString

    func testPlainMarkdownParsed() {
        let result = MarkdownConverter.toAttributedString("hello world")
        XCTAssertEqual(result.string, "hello world")
    }

    func testBoldMarkdownAppliesBoldTrait() {
        let result = MarkdownConverter.toAttributedString("**bold**")
        XCTAssertEqual(result.string, "bold")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    func testItalicMarkdownAppliesItalicTrait() {
        let result = MarkdownConverter.toAttributedString("*italic*")
        XCTAssertEqual(result.string, "italic")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    func testBoldItalicMarkdownAppliesBothTraits() {
        let result = MarkdownConverter.toAttributedString("***both***")
        XCTAssertEqual(result.string, "both")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertTrue(font!.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    func testFontSizeMatchesDefault() {
        let result = MarkdownConverter.toAttributedString("**bold** and plain")
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertEqual(font?.pointSize, DEFAULT_FONT_SIZE)
    }

    func testEmptyMarkdownReturnsEmpty() {
        let result = MarkdownConverter.toAttributedString("")
        XCTAssertEqual(result.string, "")
    }

    // MARK: - Round-trip

    func testRoundTripPlainText() {
        let original = "just some lyrics"
        let attributed = MarkdownConverter.toAttributedString(original)
        let markdown = MarkdownConverter.toMarkdown(attributed)
        XCTAssertEqual(markdown, original)
    }

    func testRoundTripBold() {
        let original = "some **bold** words"
        let attributed = MarkdownConverter.toAttributedString(original)
        let markdown = MarkdownConverter.toMarkdown(attributed)
        XCTAssertEqual(markdown, original)
    }

    func testRoundTripItalic() {
        let original = "some *italic* words"
        let attributed = MarkdownConverter.toAttributedString(original)
        let markdown = MarkdownConverter.toMarkdown(attributed)
        XCTAssertEqual(markdown, original)
    }

    func testRoundTripMixed() {
        let original = "plain **bold** *italic* ***both***"
        let attributed = MarkdownConverter.toAttributedString(original)
        let markdown = MarkdownConverter.toMarkdown(attributed)
        XCTAssertEqual(markdown, original)
    }
}
