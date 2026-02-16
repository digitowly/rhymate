import UIKit

enum TraitType {
    case bold
    case italic
}

final class TextEditorViewController: UIViewController, UITextViewDelegate {
    let textView = UITextView()
    private(set) var chordOverlay: ChordOverlayView!

    var onTextChange: ((NSAttributedString) -> Void)?
    var onSelectionChange: ((String, NSRange) -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?
    var onChordsChange: (([ChordPlacement]) -> Void)?

    var chords: [ChordPlacement] = [] {
        didSet {
            chordOverlay?.chords = chords
        }
    }

    var isChordModeActive = false {
        didSet {
            chordOverlay?.isChordModeActive = isChordModeActive
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = false

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        chordOverlay = ChordOverlayView(textView: textView)
        chordOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chordOverlay)
        NSLayoutConstraint.activate([
            chordOverlay.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            chordOverlay.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            chordOverlay.topAnchor.constraint(equalTo: textView.topAnchor),
            chordOverlay.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        ])

        chordOverlay.onChordTap = { [weak self] charIndex, existing in
            self?.showChordAlert(at: charIndex, existing: existing)
        }

        chordOverlay.onChordDragged = { [weak self] oldPlacement, newPosition in
            guard let self else { return }
            var updated = self.chords.filter { $0.position != oldPlacement.position }
            updated.append(ChordPlacement(position: newPosition, chord: oldPlacement.chord))
            updated.sort { $0.position < $1.position }
            self.chords = updated
            self.onChordsChange?(updated)
        }

        DispatchQueue.main.async { [weak self] in
            self?.recalculateHeight()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if textView.text.isEmpty {
            applyDefaultTypingAttributesIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chordOverlay?.setNeedsLayout()
    }

    func textViewDidChange(_ textView: UITextView) {
        onTextChange?(textView.attributedText)
        recalculateHeight()
        chordOverlay?.setNeedsLayout()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let delta = text.count - range.length
        var updated = chords.compactMap { placement -> ChordPlacement? in
            if placement.position >= range.location + range.length {
                return ChordPlacement(position: placement.position + delta, chord: placement.chord)
            } else if placement.position >= range.location {
                return nil
            }
            return placement
        }
        if updated != chords {
            chords = updated
            onChordsChange?(chords)
        }
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        let range = textView.selectedRange
        let selected = (textView.attributedText.string as NSString).substring(with: range)
        onSelectionChange?(selected, range)
    }

    func setText(_ newText: NSAttributedString, keepingSelection range: NSRange?) {
        guard textView.attributedText != newText else { return }
        applyDefaultTypingAttributesIfNeeded()

        let selectionToRestore = range ?? textView.selectedRange
        textView.attributedText = newText

        // Restore selection
        if selectionToRestore.location <= textView.attributedText.length {
            textView.selectedRange = selectionToRestore
        }
    }

    private func applyDefaultTypingAttributesIfNeeded() {
        textView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: DEFAULT_FONT_SIZE),
            .foregroundColor: UIColor.label
        ]
    }

    func toggleTraitAtCurrentSelection(_ type: TraitType ) -> NSAttributedString {
        let range = textView.selectedRange
        guard range.length > 0 else { return textView.attributedText }

        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)

        var trait: UIFontDescriptor.SymbolicTraits {
            switch type {
            case .bold: return .traitBold
            case .italic: return .traitItalic
            }
        }

        mutable.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            if let font = value as? UIFont {
                var traits = font.fontDescriptor.symbolicTraits
                let isTraitApplied = traits.contains(trait)

                if isTraitApplied {
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

        textView.attributedText = mutable
        textView.selectedRange = range
        return mutable
    }

    private func recalculateHeight() {
        let fittingSize = CGSize(width: textView.bounds.width > 0 ? textView.bounds.width : 300, height: .infinity)
        let newHeight = textView.sizeThatFits(fittingSize).height
        onHeightChange?(newHeight)
    }

    // MARK: - Chord Alert

    private func showChordAlert(at charIndex: Int, existing: ChordPlacement?) {
        let alert = UIAlertController(
            title: existing != nil ? "Edit Chord" : "Add Chord",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { field in
            field.placeholder = "e.g. Am, G7, Cmaj"
            field.text = existing?.chord
            field.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self,
                  let chordName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                  !chordName.isEmpty else { return }

            var updated = self.chords.filter { $0.position != (existing?.position ?? -1) }
            updated.append(ChordPlacement(position: charIndex, chord: chordName))
            updated.sort { $0.position < $1.position }
            self.chords = updated
            self.onChordsChange?(updated)
        })

        if existing != nil {
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self else { return }
                var updated = self.chords.filter { $0.position != existing?.position }
                self.chords = updated
                self.onChordsChange?(updated)
            })
        }

        present(alert, animated: true)
    }
}
