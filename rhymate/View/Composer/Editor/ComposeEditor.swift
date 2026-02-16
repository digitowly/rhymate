import SwiftUI

struct ComposeEditor: View {
    var key: String;
    @Binding var text: String
    @Binding var chords: [ChordPlacement]
    @Binding var favorites: FavoriteRhymes
    var onChange: (() -> Void)?

    @State private var isAssistantVisible = false
    @State private var selected = ""
    @State private var height: CGFloat = 400
    @State private var isChordModeActive = false

    @State private var coordinator: TextEditorContainer.Coordinator? = nil

    var body: some View {
        ZStack() {
            TextEditorContainer(
                initialText: MarkdownConverter.toAttributedString(text),
                initialHeight: height,
                chords: chords,
                isChordModeActive: isChordModeActive,
                onTextChange: { updatedText in
                    updateText(updatedText)
                },
                onSelectionChange: { selection, range in
                    DispatchQueue.main.async {
                        withAnimation {
                            self.selected = selection
                        }
                    }
                },
                onHeightChange: { updatedHeight in
                    self.height = max(updatedHeight, 600)
                },
                onChordsChange: { updatedChords in
                    DispatchQueue.main.async {
                        self.chords = updatedChords
                        onChange?()
                    }
                },
                coordinatorRef: $coordinator
            )
            .id(key)
            .frame(height: height)
        }
        .toolbar {
            ToolbarItemGroup(
                placement: .navigation
            ) {
                if $selected.wrappedValue.count >= 1 {
                    Button {
                        isAssistantVisible.toggle()
                    } label: {
                        Image(systemName: "character.book.closed")
                    }
                }
                Button {
                    isChordModeActive.toggle()
                } label: {
                    Image(systemName: "number.square")
                        .foregroundColor(isChordModeActive ? .accentColor : .secondary)
                }
                Menu {
                    Button {
                        if let updatedText = coordinator?.toggleTrait(.bold) {
                            updateText(updatedText)
                        }
                    } label: {
                        Label("bold", systemImage: "bold")
                    }
                    Button {
                        if let updatedText = coordinator?.toggleTrait(.italic) {
                            updateText(updatedText)
                        }
                    } label: {
                        Label("italic", systemImage: "italic")
                    }
                } label: {
                    Image(systemName: "textformat")
                }

            }
        }
        .sheet(isPresented: $isAssistantVisible, content: {
            NavigationStack {
                LyricAssistantView(
                    text: $selected,
                    favorites: $favorites,
                    hasAutoSubmit: true
                ).toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isAssistantVisible.toggle()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        })
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
