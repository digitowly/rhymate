import UIKit

enum MarkdownConverter {

    static func toAttributedString(_ markdown: String) -> NSAttributedString {
        guard let attributed = try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return NSAttributedString(string: markdown)
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

        return ns
    }

    static func toMarkdown(_ attributed: NSAttributedString) -> String {
        var result = ""
        let fullRange = NSRange(location: 0, length: attributed.length)

        attributed.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
            let text = (attributed.string as NSString).substring(with: range)
            let font = attrs[.font] as? UIFont
            let traits = font?.fontDescriptor.symbolicTraits ?? []

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

        return result
    }
}
