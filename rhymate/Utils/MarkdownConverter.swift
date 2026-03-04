import UIKit

extension NSAttributedString.Key {
    static let chord = NSAttributedString.Key("rhymate.chord")
}

enum MarkdownConverter {

    // Matches [Am], [C#m7], [G/B], [Fmaj7], etc. — no spaces allowed inside.
    private static let chordRegex: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"\[[A-G][A-Za-z0-9#b/]*\]"#)

    // MARK: - Chord Styling

    /// Applies chord styling to all `[Am]`-style markers in `ns`.
    /// Returns `true` if any change was made (chord ranges added, removed, or shifted).
    @discardableResult
    static func applyChordStyling(to ns: NSMutableAttributedString) -> Bool {
        let fullRange = NSRange(location: 0, length: ns.length)

        // Current chord-marked ranges
        var current: [NSRange] = []
        ns.enumerateAttribute(.chord, in: fullRange, options: []) { value, range, _ in
            if value != nil { current.append(range) }
        }

        // Ranges that should be chords per the regex
        var expected: [NSRange] = []
        chordRegex?.enumerateMatches(in: ns.string, range: fullRange) { match, _, _ in
            if let r = match?.range { expected.append(r) }
        }

        // Nothing to do if the chord ranges haven't changed
        let unchanged = current.count == expected.count
            && zip(current, expected).allSatisfy { $0 == $1 }
        if unchanged { return false }

        // Clear old chord styling
        for range in current {
            ns.removeAttribute(.chord, range: range)
            ns.addAttribute(.font, value: UIFont.systemFont(ofSize: DEFAULT_FONT_SIZE), range: range)
            ns.addAttribute(.foregroundColor, value: UIColor.label, range: range)
        }

        // Apply new chord styling
        for range in expected {
            ns.addAttribute(.font,
                            value: UIFont.monospacedSystemFont(ofSize: CHORD_FONT_SIZE, weight: .semibold),
                            range: range)
            ns.addAttribute(.foregroundColor, value: UIColor.systemPurple, range: range)
            ns.addAttribute(.chord, value: true, range: range)

            // Hide the surrounding brackets — they stay in the string for tap detection
            if range.length >= 2 {
                let open  = NSRange(location: range.location, length: 1)
                let close = NSRange(location: range.location + range.length - 1, length: 1)
                ns.addAttribute(.foregroundColor, value: UIColor.clear, range: open)
                ns.addAttribute(.foregroundColor, value: UIColor.clear, range: close)
            }
        }

        return true
    }

    // MARK: - toAttributedString

    static func toAttributedString(_ markdown: String) -> NSAttributedString {
        // Pre-process: strip heading prefix from first line before inline parsing
        var lines = markdown.components(separatedBy: "\n")
        var firstLineIsHeading = false
        if let first = lines.first, first.hasPrefix("# ") {
            firstLineIsHeading = true
            lines[0] = String(first.dropFirst(2))
        }
        let preprocessed = lines.joined(separator: "\n")

        guard let attributed = try? AttributedString(
            markdown: preprocessed,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return NSAttributedString(string: preprocessed)
        }

        let ns = NSMutableAttributedString(attributed)
        let fullRange = NSRange(location: 0, length: ns.length)

        // Apply default font and text color while preserving bold/italic traits
        ns.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            let defaultFont = UIFont.systemFont(ofSize: DEFAULT_FONT_SIZE)

            guard let existingFont = value as? UIFont else {
                ns.addAttribute(.font, value: defaultFont, range: range)
                return
            }

            let traits = existingFont.fontDescriptor.symbolicTraits
            if let descriptor = defaultFont.fontDescriptor.withSymbolicTraits(traits) {
                ns.addAttribute(.font, value: UIFont(descriptor: descriptor, size: DEFAULT_FONT_SIZE), range: range)
            } else {
                ns.addAttribute(.font, value: defaultFont, range: range)
            }
        }

        ns.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)

        // Apply heading style to first line if it had a `# ` prefix
        if firstLineIsHeading && ns.length > 0 {
            let firstLineRange = (ns.string as NSString).lineRange(for: NSRange(location: 0, length: 0))
            let headingFont = UIFont.boldSystemFont(ofSize: HEADING_FONT_SIZE)
            ns.addAttribute(.font, value: headingFont, range: firstLineRange)
        }

        applyChordStyling(to: ns)
        applyChordLineParagraphSpacing(to: ns)

        return ns
    }

    // MARK: - Chord line paragraph spacing

    /// Applies compact line spacing to paragraphs that consist only of chord tokens (and whitespace),
    /// and restores normal line spacing on paragraphs that contain any regular text.
    /// Returns `true` if any paragraph style was changed.
    @discardableResult
    static func applyChordLineParagraphSpacing(to ns: NSMutableAttributedString) -> Bool {
        var changed = false
        let nsString = ns.string as NSString
        var loc = 0

        while loc < ns.length {
            let paraRange = nsString.paragraphRange(for: NSRange(location: loc, length: 0))

            var isChordOnly = true
            var hasContent = false

            ns.enumerateAttributes(in: paraRange, options: []) { attrs, range, _ in
                let text = nsString.substring(with: range)
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                hasContent = true
                if attrs[.chord] == nil { isChordOnly = false }
            }

            let target: CGFloat = (isChordOnly && hasContent) ? CHORD_LINE_SPACING : EDITOR_LINE_SPACING
            let current = (ns.attribute(.paragraphStyle, at: paraRange.location,
                                        effectiveRange: nil) as? NSParagraphStyle)?.lineSpacing ?? 0

            if abs(current - target) > 0.1 {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = target
                ns.addAttribute(.paragraphStyle, value: style, range: paraRange)
                changed = true
            }

            loc = paraRange.location + paraRange.length
        }

        return changed
    }

    // MARK: - toMarkdown

    static func toMarkdown(_ attributed: NSAttributedString) -> String {
        let nsString = attributed.string as NSString
        guard nsString.length > 0 else { return "" }

        var result = ""

        // Check if first line has heading font
        let firstFont = attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        let firstLineIsHeading = (firstFont?.pointSize ?? DEFAULT_FONT_SIZE) >= HEADING_FONT_SIZE

        if firstLineIsHeading {
            result += "# "
        }

        let fullRange = NSRange(location: 0, length: attributed.length)

        attributed.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
            let text = nsString.substring(with: range)
            let font = attrs[.font] as? UIFont
            let fontSize = font?.pointSize ?? DEFAULT_FONT_SIZE
            let traits = font?.fontDescriptor.symbolicTraits ?? []

            // Chord text and heading text pass through as-is
            if attrs[.chord] != nil || fontSize >= HEADING_FONT_SIZE {
                result += text
            } else {
                let isBold = traits.contains(.traitBold)
                let isItalic = traits.contains(.traitItalic)

                if isBold && isItalic {
                    result += "***\(text)***"
                } else if isBold {
                    result += "**\(text)**"
                } else if isItalic {
                    result += "*\(text)*"
                } else {
                    result += text
                }
            }
        }

        return result
    }
}
