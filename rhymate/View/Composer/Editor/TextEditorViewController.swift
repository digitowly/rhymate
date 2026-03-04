import UIKit

enum TraitType {
    case bold
    case italic
}

final class TextEditorViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {
    let textView: UITextView = {
        let storage   = NSTextStorage()
        let layout    = ChordLayoutManager()
        storage.addLayoutManager(layout)
        let container = NSTextContainer(size: .zero)
        container.widthTracksTextView = true
        layout.addTextContainer(container)
        return UITextView(frame: .zero, textContainer: container)
    }()

    var onTextChange: ((NSAttributedString) -> Void)?
    var onSelectionChange: ((String, NSRange) -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?
    var onAssistantTap: (() -> Void)?
    var onBuddyTap: (() -> Void)?
    var onChordTap: (() -> Void)?
    var onChordSelected: ((String) -> Void)?

    var onKeyboardVisibilityChange: ((Bool, CGFloat) -> Void)?

    /// Tracks whether the first line should use heading style.
    /// Set during initial load from the attributed string's font.
    var firstLineIsHeading = false

    private lazy var accessoryBar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64))
        bar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        bar.setShadowImage(UIImage(), forToolbarPosition: .any)
        return bar
    }()

    private var shouldShowBuddyButton: Bool { AIFeatures.isAvailable }

    @objc private func updateToolbarItems() {
        var items: [UIBarButtonItem] = [.flexibleSpace(), chordButton, .fixedSpace(8)]
        if shouldShowBuddyButton {
            items += [buddyButton, .fixedSpace(8)]
        }
        items.append(assistantButton)
        accessoryBar.items = items
    }

    private lazy var buddyButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let image = UIImage(systemName: "sparkles", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(buddyButtonTapped), for: .touchUpInside)
        let size = CGFloat(42)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        return UIBarButtonItem(customView: button)
    }()

    @objc private func buddyButtonTapped() {
        onBuddyTap?()
    }

    private lazy var chordButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let image = UIImage(systemName: "guitars", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(chordButtonTapped), for: .touchUpInside)
        let size = CGFloat(42)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        return UIBarButtonItem(customView: button)
    }()

    @objc private func chordButtonTapped() {
        onChordTap?()
    }

    func insertChord(name: String) {
        DispatchQueue.main.async { [weak self] in
            self?.textView.becomeFirstResponder()
            self?.textView.insertText("[\(name)]")
        }
    }

    private lazy var assistantButton: UIBarButtonItem = {
        let button = UIButton(type: .system)

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let image = UIImage(systemName: "character.book.closed", withConfiguration: config)

        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(assistantButtonTapped), for: .touchUpInside)
        
        let size = CGFloat(42)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])

        return UIBarButtonItem(customView: button)
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
        textView.accessibilityIdentifier = "compose-text-view"

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

        let chordTap = ChordTapGestureRecognizer(textView: textView,
                                                  target: self,
                                                  action: #selector(handleChordTap(_:)))
        chordTap.delegate = self
        textView.addGestureRecognizer(chordTap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateToolbarItems), name: UserDefaults.didChangeNotification, object: nil)
        updateToolbarItems()
    }

    @objc private func keyboardDidShow(_ notification: Notification) {
        let height: CGFloat
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            height = frame.height
        } else {
            height = 0
        }
        onKeyboardVisibilityChange?(true, height)
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        onKeyboardVisibilityChange?(false, 0)
        if assistantAccessoryView != nil {
            hideAssistantAccessory()
        }
    }

    // MARK: - Assistant Accessory

    private var assistantAccessoryView: (UIView & InputAccessoryPanel)?

    func showBuddyAccessory(model: BuddyPanelModel, modelContainer: Any) {
        let accessory = BuddyAccessoryView(model: model, modelContainer: modelContainer)
        assistantAccessoryView = accessory
        textView.inputAccessoryView = accessory
        textView.reloadInputViews()
    }

    func showAssistantAccessory(model: AccessoryAssistantPanelModel, modelContainer: Any) {
        let accessory = AssistantAccessoryView(model: model, modelContainer: modelContainer)
        assistantAccessoryView = accessory
        textView.inputAccessoryView = accessory
        textView.reloadInputViews()
    }

    func hideAssistantAccessory() {
        assistantAccessoryView?.tearDown()
        assistantAccessoryView = nil
        textView.inputAccessoryView = accessoryBar
        textView.reloadInputViews()
        textView.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTypingAttributesForCursor()
    }

    func textViewDidChange(_ textView: UITextView) {
        enforceHeadingOnFirstLineOnly()
        applyChordStyling()
        onTextChange?(textView.attributedText)
        recalculateHeight()
    }

    private func applyChordStyling() {
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText!)
        let chordChanged   = MarkdownConverter.applyChordStyling(to: mutable)
        let spacingChanged = MarkdownConverter.applyChordLineParagraphSpacing(to: mutable)
        guard chordChanged || spacingChanged else { return }
        let sel = textView.selectedRange
        textView.attributedText = mutable
        textView.selectedRange = sel
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

    private func makeParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = EDITOR_LINE_SPACING
        return style
    }

    private func updateTypingAttributesForCursor() {
        let paragraphStyle = makeParagraphStyle()
        if firstLineIsHeading && cursorIsOnFirstLine() {
            textView.typingAttributes = [
                .font: UIFont.boldSystemFont(ofSize: HEADING_FONT_SIZE),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraphStyle
            ]
        } else {
            textView.typingAttributes = [
                .font: UIFont.systemFont(ofSize: DEFAULT_FONT_SIZE),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraphStyle
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

    // MARK: - Chord Tap

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc private func handleChordTap(_ gesture: ChordTapGestureRecognizer) {
        guard let name = gesture.detectedChordName else { return }
        // Restore cursor to where it was before the tap landed on the chord
        let savedSelection = textView.selectedRange
        onChordSelected?(name)
        DispatchQueue.main.async { [weak self] in
            self?.textView.selectedRange = savedSelection
        }
    }

    private func recalculateHeight() {
        let fittingSize = CGSize(width: textView.bounds.width > 0 ? textView.bounds.width : 300, height: .infinity)
        let newHeight = textView.sizeThatFits(fittingSize).height
        onHeightChange?(newHeight)
    }
}

// MARK: - Chord tap gesture recognizer

/// Succeeds only when the tap lands on a chord token; fails immediately otherwise.
/// This lets `shouldBeRequiredToFailBy` block UITextView's cursor-placement gesture
/// without affecting non-chord taps.
private final class ChordTapGestureRecognizer: UIGestureRecognizer {
    private(set) var detectedChordName: String?
    private weak var textView: UITextView?

    init(textView: UITextView, target: Any?, action: Selector?) {
        self.textView = textView
        super.init(target: target, action: action)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        // Discrete gesture — remain in .possible until touchesEnded
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        detectedChordName = nil
        guard let textView, let touch = touches.first,
              touches.count == 1 else { state = .failed; return }

        if let name = chordName(at: touch.location(in: textView)) {
            detectedChordName = name
            state = .recognized
        } else {
            state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .cancelled
    }

    private func chordName(at location: CGPoint) -> String? {
        guard let textView else { return nil }
        let inset = textView.textContainerInset
        let point = CGPoint(x: location.x - inset.left, y: location.y - inset.top)
        var fraction: CGFloat = 0
        let charIndex = textView.layoutManager.characterIndex(
            for: point, in: textView.textContainer,
            fractionOfDistanceBetweenInsertionPoints: &fraction)
        guard charIndex < textView.attributedText.length,
              textView.attributedText.attribute(.chord, at: charIndex, effectiveRange: nil) != nil
        else { return nil }
        var chordRange = NSRange()
        let fullRange = NSRange(location: 0, length: textView.attributedText.length)
        textView.attributedText.attribute(.chord, at: charIndex,
                                          longestEffectiveRange: &chordRange, in: fullRange)
        let raw = (textView.attributedText.string as NSString).substring(with: chordRange)
        let name = String(raw.dropFirst().dropLast())
        return name.isEmpty ? nil : name
    }
}

// MARK: - Chord pill background

private final class ChordLayoutManager: NSLayoutManager {
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage else { return }

        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.chord, in: charRange, options: []) { value, range, _ in
            guard value != nil else { return }

            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            enumerateLineFragments(forGlyphRange: glyphRange) { _, _, container, lineGlyphRange, _ in
                let intersection = NSIntersectionRange(glyphRange, lineGlyphRange)
                guard intersection.length > 0 else { return }

                let rect = self.boundingRect(forGlyphRange: intersection, in: container)
                    .offsetBy(dx: origin.x, dy: origin.y)
                    .insetBy(dx: -5, dy: -2)

                let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
                UIColor.systemPurple.withAlphaComponent(0.13).setFill()
                path.fill()
            }
        }
    }
}
