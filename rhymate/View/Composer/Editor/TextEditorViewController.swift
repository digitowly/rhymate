import UIKit

enum TraitType {
    case bold
    case italic
}

final class TextEditorViewController: UIViewController, UITextViewDelegate {
    let textView = UITextView()

    var onTextChange: ((NSAttributedString) -> Void)?
    var onSelectionChange: ((String, NSRange) -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?
    var onAssistantTap: (() -> Void)?

    var onKeyboardVisibilityChange: ((Bool) -> Void)?

    /// Tracks whether the first line should use heading style.
    /// Set during initial load from the attributed string's font.
    var firstLineIsHeading = false

    private lazy var accessoryBar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 52))
        bar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        bar.setShadowImage(UIImage(), forToolbarPosition: .any)
        bar.items = [
            UIBarButtonItem.flexibleSpace(),
            assistantButton
        ]
        return bar
    }()

    private lazy var assistantButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "character.book.closed"),
            style: .plain,
            target: self,
            action: #selector(assistantButtonTapped)
        )
    }()

    @objc private func assistantButtonTapped() {
        onAssistantTap?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.inputAccessoryView = accessoryBar

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        DispatchQueue.main.async { [weak self] in
            self?.recalculateHeight()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    @objc private func keyboardDidShow() {
        onKeyboardVisibilityChange?(true)
    }

    @objc private func keyboardDidHide() {
        onKeyboardVisibilityChange?(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTypingAttributesForCursor()
    }

    func textViewDidChange(_ textView: UITextView) {
        enforceHeadingOnFirstLineOnly()
        onTextChange?(textView.attributedText)
        recalculateHeight()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        let range = textView.selectedRange
        let selected = (textView.attributedText.string as NSString).substring(with: range)
        onSelectionChange?(selected, range)
        updateTypingAttributesForCursor()
    }

    func setText(_ newText: NSAttributedString, keepingSelection range: NSRange?) {
        guard textView.attributedText != newText else { return }

        let selectionToRestore = range ?? textView.selectedRange
        textView.attributedText = newText

        // Restore selection
        if selectionToRestore.location <= textView.attributedText.length {
            textView.selectedRange = selectionToRestore
        }
        updateTypingAttributesForCursor()
    }

    // MARK: - Typing Attributes

    private func updateTypingAttributesForCursor() {
        if firstLineIsHeading && cursorIsOnFirstLine() {
            textView.typingAttributes = [
                .font: UIFont.boldSystemFont(ofSize: HEADING_FONT_SIZE),
                .foregroundColor: UIColor.label
            ]
        } else {
            textView.typingAttributes = [
                .font: UIFont.systemFont(ofSize: DEFAULT_FONT_SIZE),
                .foregroundColor: UIColor.label
            ]
        }
    }

    private func cursorIsOnFirstLine() -> Bool {
        let cursorPos = textView.selectedRange.location
        let nsString = textView.text as NSString
        if nsString.length == 0 { return true }
        let firstLineRange = nsString.lineRange(for: NSRange(location: 0, length: 0))
        return cursorPos <= firstLineRange.location + firstLineRange.length
    }

    // MARK: - Heading

    /// After every edit, ensure only the first line carries heading font.
    /// If the user pressed Enter on a heading line, the new second line
    /// inherits heading font — this resets it back to body font.
    private func enforceHeadingOnFirstLineOnly() {
        guard firstLineIsHeading else { return }
        let nsString = textView.text as NSString
        guard nsString.length > 0 else { return }

        let firstLineRange = nsString.lineRange(for: NSRange(location: 0, length: 0))
        let restStart = firstLineRange.location + firstLineRange.length
        guard restStart < nsString.length else { return }

        let restRange = NSRange(location: restStart, length: nsString.length - restStart)
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText!)
        var changed = false

        mutable.enumerateAttribute(.font, in: restRange, options: []) { value, range, _ in
            if let font = value as? UIFont, font.pointSize >= HEADING_FONT_SIZE {
                let bodyFont = UIFont.systemFont(ofSize: DEFAULT_FONT_SIZE)
                mutable.addAttribute(.font, value: bodyFont, range: range)
                changed = true
            }
        }

        if changed {
            let sel = textView.selectedRange
            textView.attributedText = mutable
            textView.selectedRange = sel
        }
    }

    func toggleHeadingOnFirstLine() -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText!)
        let nsString = mutable.string as NSString
        let cursorLocation = textView.selectedRange.location

        if nsString.length == 0 {
            // Empty document — just flip the flag
            firstLineIsHeading.toggle()
            updateTypingAttributesForCursor()
            return textView.attributedText
        }

        let firstLineRange = nsString.lineRange(for: NSRange(location: 0, length: 0))

        if firstLineIsHeading {
            // Turn off heading
            firstLineIsHeading = false
            let bodyFont = UIFont.systemFont(ofSize: DEFAULT_FONT_SIZE)
            mutable.addAttribute(.font, value: bodyFont, range: firstLineRange)
        } else {
            // Turn on heading
            firstLineIsHeading = true
            let headingFont = UIFont.boldSystemFont(ofSize: HEADING_FONT_SIZE)
            mutable.addAttribute(.font, value: headingFont, range: firstLineRange)
        }

        textView.attributedText = mutable
        textView.selectedRange = NSRange(location: cursorLocation, length: 0)
        updateTypingAttributesForCursor()
        return textView.attributedText
    }

    func toggleTraitAtCurrentSelection(_ type: TraitType ) -> NSAttributedString {
        let range = textView.selectedRange
        guard range.length > 0 else { return textView.attributedText }

        let trait: UIFontDescriptor.SymbolicTraits = switch type {
        case .bold: .traitBold
        case .italic: .traitItalic
        }

        let result = ComposerLogic.toggleTrait(trait, in: textView.attributedText, over: range)
        textView.attributedText = result
        textView.selectedRange = range
        return result
    }

    private func recalculateHeight() {
        let fittingSize = CGSize(width: textView.bounds.width > 0 ? textView.bounds.width : 300, height: .infinity)
        let newHeight = textView.sizeThatFits(fittingSize).height
        onHeightChange?(newHeight)
    }
}
