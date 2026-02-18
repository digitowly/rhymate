import SwiftUI
import SwiftData
import UIKit

// MARK: - Bridge Model

final class AccessoryAssistantPanelModel: ObservableObject {
    @Published var selectedWord: String
    @Published var searchTerm: String = ""
    var onClose: (() -> Void)?

    init(selectedWord: String) {
        self.selectedWord = selectedWord
    }
}

// MARK: - SwiftUI Panel

struct AccessoryAssistantPanel: View {
    @ObservedObject var model: AccessoryAssistantPanelModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.searchTerm.isEmpty ? "Rhyme Assistant" : model.searchTerm)
                    .font(.headline)
                Spacer()
                Button {
                    model.onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

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

// MARK: - UIKit Accessory View

final class AssistantAccessoryView: UIView {
    private static let viewHeight: CGFloat = 220

    private var hostingController: UIHostingController<AnyView>?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.viewHeight)
    }

    init(model: AccessoryAssistantPanelModel, modelContainer: Any) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: Self.viewHeight))
        autoresizingMask = .flexibleWidth

        var panel = AnyView(AccessoryAssistantPanel(model: model))
        if let container = modelContainer as? ModelContainer {
            panel = AnyView(panel.modelContainer(container))
        }

        let hosting = UIHostingController(rootView: panel)
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
