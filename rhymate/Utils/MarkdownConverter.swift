import UIKit

enum MarkdownConverter {

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

        return ns
    }

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

            // Don't wrap heading-sized text in bold markers
            if fontSize >= HEADING_FONT_SIZE {
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
