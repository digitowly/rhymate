import SwiftUI
import SwiftData
import UIKit

// MARK: - Protocol

protocol InputAccessoryPanel: AnyObject {
    func tearDown()
}

// MARK: - Shared Base (UIKit)

class HostedPanelView: UIView, InputAccessoryPanel {
    static let panelHeight: CGFloat = 220

    private var hostingController: UIHostingController<AnyView>?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.panelHeight)
    }

    init(panel: some View, modelContainer: Any) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: Self.panelHeight))
        autoresizingMask = .flexibleWidth

        var anyPanel = AnyView(panel)
        if let container = modelContainer as? ModelContainer {
            anyPanel = AnyView(anyPanel.modelContainer(container))
        }

        let hosting = UIHostingController(rootView: anyPanel)
        hosting.view.backgroundColor = .clear
        hostingController = hosting

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tearDown() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }
}

// MARK: - Shared Header (SwiftUI)

struct ComposerAccessoryPanelHeader: View {
    let title: String
    let systemImage: String?
    let onClose: () -> Void

    var body: some View {
        HStack {
            if let systemImage {
                Label(title, systemImage: systemImage)
                    .font(.headline)
            } else {
                Text(title)
                    .font(.headline)
            }
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Assistant Bridge Model

final class AccessoryAssistantPanelModel: ObservableObject {
    @Published var selectedWord: String
    @Published var searchTerm: String = ""
    var onClose: (() -> Void)?

    init(selectedWord: String) {
        self.selectedWord = selectedWord
    }
}

// MARK: - Assistant SwiftUI Panel

struct AccessoryAssistantPanel: View {
    @ObservedObject var model: AccessoryAssistantPanelModel

    var body: some View {
        VStack(spacing: 0) {
            ComposerAccessoryPanelHeader(
                title: model.searchTerm.isEmpty ? "Rhymes" : model.searchTerm,
                systemImage: nil,
                onClose: { model.onClose?() }
            )

            Divider()

            LyricAssistantView(
                text: $model.selectedWord,
                hasAutoSubmit: true,
                suppressAutoFocus: true,
                onSearchTermChange: { term in
                    model.searchTerm = term
                }
            )
        }
        .background(.regularMaterial)
    }
}

// MARK: - Assistant UIKit Accessory View

final class AssistantAccessoryView: HostedPanelView {
    init(model: AccessoryAssistantPanelModel, modelContainer: Any) {
        super.init(panel: AccessoryAssistantPanel(model: model), modelContainer: modelContainer)
    }
}

// MARK: - Buddy Bridge Model

final class BuddyPanelModel: ObservableObject {
    @Published var phrase: String
    var onClose: (() -> Void)?

    init(phrase: String) {
        self.phrase = phrase
    }
}

// MARK: - Buddy SwiftUI Panel

struct BuddyAccessoryPanel: View {
    @ObservedObject var model: BuddyPanelModel

    var body: some View {
        VStack(spacing: 0) {
            ComposerAccessoryPanelHeader(
                title: "Inspire",
                systemImage: "sparkles",
                onClose: { model.onClose?() }
            )

            Divider()

            LyricBuddyView(initialPhrase: model.phrase)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Buddy UIKit Accessory View

final class BuddyAccessoryView: HostedPanelView {
    init(model: BuddyPanelModel, modelContainer: Any) {
        super.init(panel: BuddyAccessoryPanel(model: model), modelContainer: modelContainer)
    }
}
