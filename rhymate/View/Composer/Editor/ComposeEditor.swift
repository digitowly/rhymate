import SwiftUI

struct ComposeEditor: View {
    var key: String;
    @Binding var text: String
    var onChange: (() -> Void)?

    @Binding var isAssistantVisible: Bool
    @Binding var selectedWord: String
    @State private var coordinatorRef: TextEditorContainer.Coordinator?

    @State private var height: CGFloat = 400
    @State private var isKeyboardVisible = false

    var body: some View {
        ZStack {
            TextEditorContainer(
                initialText: MarkdownConverter.toAttributedString(text),
                initialFirstLineIsHeading: text.hasPrefix("# "),
                initialHeight: height,
                onTextChange: { updatedText in
                    updateText(updatedText)
                },
                onSelectionChange: { selection, range in
                    DispatchQueue.main.async {
                        withAnimation {
                            self.selectedWord = selection
                        }
                    }
                },
                onHeightChange: { updatedHeight in
                    self.height = max(updatedHeight, 600)
                },
                onAssistantTap: {
                    withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                        isAssistantVisible = true
                    }
                },
                onKeyboardVisibilityChange: { visible in
                    withAnimation {
                        isKeyboardVisible = visible
                    }
                },
                coordinatorRef: $coordinatorRef
            )
            .id(key)
            .frame(height: height)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if !isKeyboardVisible {
                    Button {
                        withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                            isAssistantVisible = true
                        }
                    } label: {
                        Image(systemName: "character.book.closed")
                    }
                }
                Menu {
                    Button {
                        if let updatedText = coordinatorRef?.toggleHeading() {
                            updateText(updatedText)
                        }
                    } label: {
                        Label("Heading", systemImage: "number")
                    }
                    Button {
                        if let updatedText = coordinatorRef?.toggleTrait(.bold) {
                            updateText(updatedText)
                        }
                    } label: {
                        Label("Bold", systemImage: "bold")
                    }
                    Button {
                        if let updatedText = coordinatorRef?.toggleTrait(.italic) {
                            updateText(updatedText)
                        }
                    } label: {
                        Label("Italic", systemImage: "italic")
                    }
                } label: {
                    Image(systemName: "textformat")
                }
            }
        }
    }

    private func updateText(_ updatedText: NSAttributedString) {
        DispatchQueue.main.async {
            self.text = MarkdownConverter.toMarkdown(updatedText)
            onChange?()
        }
    }
}

#Preview {
    //    ComposeEditor()
}
