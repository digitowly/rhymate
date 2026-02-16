import SwiftUI

struct TextEditorContainer: UIViewControllerRepresentable {
    class Coordinator {
        var controller: TextEditorViewController?
        var onTextChange: ((NSAttributedString) -> Void)?
        var onSelectionChange: ((String, NSRange) -> Void)?
        var onHeightChange: ((CGFloat) -> Void)?
        var onChordsChange: (([ChordPlacement]) -> Void)?

        func toggleTrait(_ type: TraitType) -> NSAttributedString? {
            return controller?.toggleTraitAtCurrentSelection(type)
        }

        func setChordMode(_ active: Bool) {
            controller?.isChordModeActive = active
        }

        func updateChords(_ chords: [ChordPlacement]) {
            controller?.chords = chords
        }
    }

    let initialText: NSAttributedString
    let initialHeight: CGFloat
    let chords: [ChordPlacement]
    let isChordModeActive: Bool
    var onTextChange: ((NSAttributedString) -> Void)? = nil
    var onSelectionChange: ((String, NSRange) -> Void)? = nil
    var onHeightChange: ((CGFloat) -> Void)? = nil
    var onChordsChange: (([ChordPlacement]) -> Void)? = nil
    @Binding var coordinatorRef: TextEditorContainer.Coordinator?

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.onTextChange = onTextChange
        coordinator.onSelectionChange = onSelectionChange
        coordinator.onHeightChange = onHeightChange
        coordinator.onChordsChange = onChordsChange
        return coordinator
    }

    func makeUIViewController(context: Context) -> TextEditorViewController {
        let vc = TextEditorViewController()
        vc.onTextChange = context.coordinator.onTextChange
        vc.onSelectionChange = context.coordinator.onSelectionChange
        vc.onHeightChange = context.coordinator.onHeightChange
        vc.onChordsChange = context.coordinator.onChordsChange
        context.coordinator.controller = vc

        vc.textView.attributedText = ensureFont(in: initialText)
        vc.chords = chords
        vc.isChordModeActive = isChordModeActive

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

        return mutable
    }


    func updateUIViewController(_ uiViewController: TextEditorViewController, context: Context) {
        context.coordinator.controller?.isChordModeActive = isChordModeActive
        context.coordinator.controller?.chords = chords
    }
}
