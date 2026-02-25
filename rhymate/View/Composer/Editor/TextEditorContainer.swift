import SwiftUI
import SwiftData

struct TextEditorContainer: UIViewControllerRepresentable {
    class Coordinator {
        var controller: TextEditorViewController?
        var onTextChange: ((NSAttributedString) -> Void)?
        var onSelectionChange: ((String, NSRange) -> Void)?
        var onHeightChange: ((CGFloat) -> Void)?
        var onAssistantTap: (() -> Void)?
        var onKeyboardVisibilityChange: ((Bool, CGFloat) -> Void)?
        var onAccessoryAssistantDismissed: (() -> Void)?

        var panelModel: AccessoryAssistantPanelModel?

        func toggleTrait(_ type: TraitType) -> NSAttributedString? {
            return controller?.toggleTraitAtCurrentSelection(type)
        }

        func toggleHeading() -> NSAttributedString? {
            return controller?.toggleHeadingOnFirstLine()
        }

        func focus() {
            controller?.textView.becomeFirstResponder()
        }

        func showAccessoryAssistant(selectedWord: String, modelContainer: ModelContainer) {
            let model = AccessoryAssistantPanelModel(selectedWord: selectedWord)
            model.onClose = { [weak self] in
                self?.hideAccessoryAssistant()
            }
            panelModel = model
            controller?.showAssistantAccessory(model: model, modelContainer: modelContainer)
        }

        func hideAccessoryAssistant() {
            controller?.hideAssistantAccessory()
            panelModel = nil
            onAccessoryAssistantDismissed?()
        }

        func updateAccessorySelectedWord(_ word: String) {
            panelModel?.selectedWord = word
        }
    }

    let initialText: NSAttributedString
    let initialFirstLineIsHeading: Bool
    let initialHeight: CGFloat
    var onTextChange: ((NSAttributedString) -> Void)? = nil
    var onSelectionChange: ((String, NSRange) -> Void)? = nil
    var onHeightChange: ((CGFloat) -> Void)? = nil
    var onAssistantTap: (() -> Void)? = nil
    var onKeyboardVisibilityChange: ((Bool, CGFloat) -> Void)? = nil
    var onAccessoryAssistantDismissed: (() -> Void)? = nil
    @Binding var coordinatorRef: TextEditorContainer.Coordinator?

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.onTextChange = onTextChange
        coordinator.onSelectionChange = onSelectionChange
        coordinator.onHeightChange = onHeightChange
        coordinator.onAssistantTap = onAssistantTap
        coordinator.onKeyboardVisibilityChange = onKeyboardVisibilityChange
        coordinator.onAccessoryAssistantDismissed = onAccessoryAssistantDismissed
        return coordinator
    }

    func makeUIViewController(context: Context) -> TextEditorViewController {
        let vc = TextEditorViewController()
        vc.onTextChange = context.coordinator.onTextChange
        vc.onSelectionChange = context.coordinator.onSelectionChange
        vc.onHeightChange = context.coordinator.onHeightChange
        vc.onAssistantTap = context.coordinator.onAssistantTap
        vc.onKeyboardVisibilityChange = context.coordinator.onKeyboardVisibilityChange
        context.coordinator.controller = vc

        let prepared = ensureFont(in: initialText)
        vc.textView.attributedText = prepared

        // Detect heading from attributed content or from the flag (for empty docs)
        if prepared.length > 0 {
            let font = prepared.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            vc.firstLineIsHeading = (font?.pointSize ?? DEFAULT_FONT_SIZE) >= HEADING_FONT_SIZE
        } else {
            vc.firstLineIsHeading = initialFirstLineIsHeading
        }

        DispatchQueue.main.async {
            self.coordinatorRef = context.coordinator
        }

        return vc
    }

    private func ensureFont(
        in attributed: NSAttributedString,
        defaultFont: UIFont = .systemFont(ofSize: DEFAULT_FONT_SIZE)
    ) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        let fullRange = NSRange(location: 0, length: mutable.length)

        mutable.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if value == nil {
                mutable.addAttribute(.font, value: defaultFont, range: range)
            }
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = EDITOR_LINE_SPACING
        mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        return mutable
    }


    func updateUIViewController(_ uiViewController: TextEditorViewController, context: Context) {
        // do nothing to prevent re-renders via SwiftUI
    }
}
