import UIKit

// MARK: - Chord Bubble View

private final class ChordBubbleView: UIView {

    let label = UILabel()
    var placement: ChordPlacement

    init(placement: ChordPlacement) {
        self.placement = placement
        super.init(frame: .zero)

        let accent = UIColor(named: "AccentColor") ?? .systemGreen

        backgroundColor = accent.withAlphaComponent(0.12)
        layer.cornerRadius = CHORD_LABEL_HEIGHT / 2

        label.text = placement.chord
        label.font = .monospacedSystemFont(ofSize: CHORD_FONT_SIZE, weight: .semibold)
        label.textColor = accent
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CHORD_BUBBLE_PADDING),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CHORD_BUBBLE_PADDING),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func updateText(_ text: String) {
        label.text = text
        placement = ChordPlacement(position: placement.position, chord: text)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = label.intrinsicContentSize
        return CGSize(width: labelSize.width + CHORD_BUBBLE_PADDING * 2,
                      height: CHORD_LABEL_HEIGHT)
    }
}

// MARK: - Chord Overlay View

final class ChordOverlayView: UIView {

    private weak var textView: UITextView?

    // Lane layer for drawing horizontal guide lines
    private let laneLayer = CAShapeLayer()

    // Bubble views keyed by chord position for stable identity
    private var bubbleViews: [ChordBubbleView] = []

    // Drag state
    private var draggedBubble: ChordBubbleView?
    private var dragLaneMinX: CGFloat = 0
    private var dragLaneMaxX: CGFloat = 0
    private var dragLaneY: CGFloat = 0

    var chords: [ChordPlacement] = [] {
        didSet { setNeedsLayout() }
    }

    var isChordModeActive = false {
        didSet {
            isUserInteractionEnabled = isChordModeActive
            animateLanes(visible: isChordModeActive)
        }
    }

    var onChordTap: ((_ characterIndex: Int, _ existing: ChordPlacement?) -> Void)?
    var onChordDragged: ((_ chord: ChordPlacement, _ newPosition: Int) -> Void)?

    init(textView: UITextView) {
        self.textView = textView
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        // Lane layer setup
        laneLayer.strokeColor = UIColor.separator.cgColor
        laneLayer.lineWidth = 0.5
        laneLayer.fillColor = nil
        laneLayer.opacity = 0
        layer.addSublayer(laneLayer)

        // Tap gesture for adding/editing chords
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        // Pan gesture for dragging bubbles
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        laneLayer.frame = bounds
        rebuildLanes()
        rebuildBubbles()
    }

    // MARK: - Lanes

    private func rebuildLanes() {
        guard let textView else {
            laneLayer.path = nil
            return
        }

        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        let inset = textView.textContainerInset
        let path = UIBezierPath()

        layoutManager.enumerateLineFragments(
            forGlyphRange: layoutManager.glyphRange(for: textContainer)
        ) { rect, _, _, _, _ in
            let y = rect.minY + inset.top - CHORD_LABEL_HEIGHT - CHORD_LANE_INSET
            let adjustedY = y - inset.top  // offset because overlay is pinned to textView
            let lineStartX = rect.minX + inset.left - inset.left  // relative to overlay
            let lineEndX = self.bounds.width

            path.move(to: CGPoint(x: lineStartX, y: adjustedY))
            path.addLine(to: CGPoint(x: lineEndX, y: adjustedY))
        }

        laneLayer.path = path.cgPath
    }

    private func animateLanes(visible: Bool) {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = laneLayer.opacity
        anim.toValue = visible ? 1.0 : 0.0
        anim.duration = 0.25
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        laneLayer.opacity = visible ? 1.0 : 0.0
        laneLayer.add(anim, forKey: "laneOpacity")
    }

    // MARK: - Bubbles

    private func rebuildBubbles() {
        // Remove old bubbles
        bubbleViews.forEach { $0.removeFromSuperview() }
        bubbleViews.removeAll()

        guard let textView else { return }
        let inset = textView.textContainerInset

        for placement in chords {
            guard placement.position <= textView.text.count else { continue }

            let caretRect = caretRect(for: placement.position, in: textView)
            guard caretRect != .null else { continue }

            let bubble = ChordBubbleView(placement: placement)
            let bubbleSize = bubble.intrinsicContentSize

            // x: align bubble start with character position
            let x = caretRect.origin.x - inset.left
            // y: center on the lane line for this text line
            let lineFragmentRect = lineFragment(containing: placement.position, in: textView)
            let laneY = lineFragmentRect.minY + inset.top - CHORD_LABEL_HEIGHT - CHORD_LANE_INSET - inset.top
            let y = laneY - bubbleSize.height / 2

            bubble.frame = CGRect(
                x: max(0, x),
                y: max(0, y),
                width: bubbleSize.width,
                height: bubbleSize.height
            )

            addSubview(bubble)
            bubbleViews.append(bubble)
        }
    }

    // MARK: - Hit Testing

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let textView else { return }

        let locationInOverlay = gesture.location(in: self)

        // Check if tap hit an existing bubble
        if let bubble = bubbleViews.first(where: { $0.frame.contains(locationInOverlay) }) {
            onChordTap?(bubble.placement.position, bubble.placement)
            return
        }

        // Convert to textView coordinates
        let locationInTextView = gesture.location(in: textView)
        let charIndex = characterIndex(at: locationInTextView, in: textView)
        onChordTap?(charIndex, nil)
    }

    // MARK: - Drag

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let textView else { return }
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            // Find which bubble was touched
            guard let bubble = bubbleViews.first(where: {
                $0.frame.insetBy(dx: -8, dy: -8).contains(location)
            }) else { return }

            draggedBubble = bubble

            // Determine lane bounds for clamping
            let lineRect = lineFragment(containing: bubble.placement.position, in: textView)
            let inset = textView.textContainerInset
            dragLaneMinX = 0
            dragLaneMaxX = bounds.width - bubble.frame.width
            dragLaneY = bubble.frame.origin.y

            UIView.animate(withDuration: 0.15) {
                bubble.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
                bubble.alpha = 0.85
            }

        case .changed:
            guard let bubble = draggedBubble else { return }
            let newX = min(dragLaneMaxX, max(dragLaneMinX, location.x - bubble.frame.width / 2))
            bubble.frame.origin = CGPoint(x: newX, y: dragLaneY)

        case .ended, .cancelled:
            guard let bubble = draggedBubble else { return }

            UIView.animate(withDuration: 0.15) {
                bubble.transform = .identity
                bubble.alpha = 1.0
            }

            // Convert final x position to character index
            let inset = textView.textContainerInset
            let pointInTextView = CGPoint(
                x: bubble.frame.origin.x + inset.left,
                y: bubble.frame.midY + inset.top
            )
            let newCharIndex = characterIndex(at: pointInTextView, in: textView)
            let oldPlacement = bubble.placement

            draggedBubble = nil

            if newCharIndex != oldPlacement.position {
                onChordDragged?(oldPlacement, newCharIndex)
            } else {
                // Snap back
                setNeedsLayout()
            }

        default:
            break
        }
    }

    // MARK: - Geometry Helpers

    private func caretRect(for characterIndex: Int, in textView: UITextView) -> CGRect {
        let safeIndex = min(characterIndex, textView.text.count)
        guard let start = textView.position(from: textView.beginningOfDocument, offset: safeIndex),
              let end = textView.position(from: start, offset: 0),
              let range = textView.textRange(from: start, to: end) else {
            return .null
        }
        return textView.firstRect(for: range)
    }

    private func lineFragment(containing characterIndex: Int, in textView: UITextView) -> CGRect {
        let layoutManager = textView.layoutManager
        let safeIndex = min(characterIndex, layoutManager.numberOfGlyphs.advanced(by: -1))
        guard safeIndex >= 0 else { return .zero }
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: safeIndex)
        var lineRect = CGRect.zero
        layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: false)
        lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        return lineRect
    }

    private func characterIndex(at point: CGPoint, in textView: UITextView) -> Int {
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        let glyphIndex = layoutManager.glyphIndex(
            for: point,
            in: textContainer,
            fractionOfDistanceThroughGlyph: nil
        )
        return layoutManager.characterIndexForGlyph(at: glyphIndex)
    }
}
