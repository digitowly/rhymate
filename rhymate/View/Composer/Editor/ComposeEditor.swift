import SwiftUI

struct ComposeEditor: View {
    var key: String;
    @Binding var text: String
    var onChange: (() -> Void)?

    @Binding var isAssistantVisible: Bool
    @Binding var isBuddyVisible: Bool
    @Binding var selectedWord: String
    @State private var coordinatorRef: TextEditorContainer.Coordinator?

    @Environment(\.modelContext) private var modelContext
    @State private var height: CGFloat = 400
    @State private var isKeyboardVisible = false
    @State private var keyboardHeight: CGFloat = 0

    private var useAccessoryMode: Bool {
        guard isKeyboardVisible, keyboardHeight > 0 else { return false }
        let availableHeight = UIScreen.main.bounds.height - keyboardHeight
        return availableHeight < 420
    }

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
                    if useAccessoryMode {
                        coordinatorRef?.showAccessoryAssistant(selectedWord: selectedWord, modelContainer: modelContext.container)
                    } else {
                        withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                            isAssistantVisible = true
                        }
                    }
                },
                onBuddyTap: {
                    if useAccessoryMode {
                        coordinatorRef?.showAccessoryBuddy(phrase: selectedWord, modelContainer: modelContext.container)
                    } else {
                        withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                            isBuddyVisible = true
                        }
                    }
                },
                onKeyboardVisibilityChange: { visible, height in
                    withAnimation {
                        isKeyboardVisible = visible
                    }
                    keyboardHeight = height
                },
                onAccessoryAssistantDismissed: { },
                coordinatorRef: $coordinatorRef
            )
            .id(key)
            .frame(height: height)
            .accessibilityIdentifier("compose-editor")
            .onChange(of: selectedWord) { _, newValue in
                if coordinatorRef?.panelModel != nil {
                    coordinatorRef?.updateAccessorySelectedWord(newValue)
                }
                if coordinatorRef?.buddyPanelModel != nil {
                    coordinatorRef?.updateAccessoryBuddyPhrase(newValue)
                }
            }
            .onChange(of: isAssistantVisible) { _, visible in
                if !visible {
                    DispatchQueue.main.asyncAfter(deadline: .now() ) {
                        coordinatorRef?.focus()
                    }
                }
            }
            .onChange(of: isBuddyVisible) { _, visible in
                if !visible {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        coordinatorRef?.focus()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
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
