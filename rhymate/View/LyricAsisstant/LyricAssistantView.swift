import SwiftUI

struct LyricAssistantView: View {
    @Binding var text: String
    var hasAutoSubmit = false
    var onSearchTermChange: ((String) -> Void)?

    @State private var searchText: String = ""
    @FocusState private var isInputFocused: Bool

    private var words: [String] {
        text.split(separator: " ").map { Formatter.normalize(String($0)) }
    }

    private var isSendButtonVisible: Bool {
        guard let lastWord = words.last else { return false }
        return lastWord != searchText
    }

    private func submit(_ word: String) {
        searchText = word
        onSearchTermChange?(word)
    }

    var body: some View {
        VStack(spacing: 0) {
            if searchText.isEmpty {
                Spacer()
                LyricAssistantEmptyView()
                Spacer()
            } else {
                ScrollView {
                    RhymesView(word: searchText)
                }
                .transaction { $0.animation = nil }
            }

            Divider()
            inputBar
                .padding(.top, 8)
        }
        .onAppear {
            if hasAutoSubmit, words.count == 1, let word = words.first {
                searchText = word
                onSearchTermChange?(word)
            }
            isInputFocused = true
        }
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            if words.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(words, id: \.self) { word in
                            Button(word) { submit(word) }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.quinary)
                                .clipShape(Capsule())
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type a word…", text: $text)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                    .submitLabel(.search)
                    .onSubmit {
                        if let word = words.last {
                            submit(word)
                        }
                    }

                Button(action: {
                    if let word = words.last {
                        submit(word)
                    }
                }) {
                    Label("Search", systemImage: "arrow.up")
                        .labelStyle(.iconOnly)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(isSendButtonVisible ? 1 : 0)
                .disabled(!isSendButtonVisible)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

private struct LyricAssistantPreview: View {
    @State var text: String = "Hello World"

    var body: some View {
        LyricAssistantView(text: $text)
    }
}

#Preview {
    LyricAssistantPreview()
}
