import SwiftUI

struct LyricBuddyView: View {
    var initialPhrase: String
    var onSuggestionTap: ((String, String) -> Void)?

    private let service = LyricService()
    @State private var inputPhrase: String = ""
    @State private var submittedPhrase: String = ""
    @State private var suggestions: [String] = []
    @State private var isLoading = false
    @State private var failed = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if isLoading {
                    LoadingSpinner()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if submittedPhrase.isEmpty {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "Get Inspired",
                        description: "Type a line below to get inspired"
                    )
                } else if failed || suggestions.isEmpty {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No Suggestions",
                        description: "Couldn't generate suggestions. Try a longer phrase."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    onSuggestionTap?(submittedPhrase, suggestion)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Text(suggestion)
                                            .font(.system(.headline))
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                }
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(18)
                            }
                        }
                        .padding()
                    }
                }
            }

            Divider()

            inputBar
                .padding(.top, 8)
        }
        .onAppear {
            inputPhrase = initialPhrase
            if !initialPhrase.isEmpty {
                submittedPhrase = initialPhrase
            }
        }
        .task(id: submittedPhrase) {
            guard !submittedPhrase.isEmpty else { return }
            withAnimation { isLoading = true; failed = false }
            let result = await service.getSuggestedLines(forPhrase: submittedPhrase)
            withAnimation {
                switch result {
                case .success(let lines): suggestions = lines
                case .failure: failed = suggestions.isEmpty
                }
                isLoading = false
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Type a line…", text: $inputPhrase)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .submitLabel(.done)
                .onSubmit { submitInput() }

            Button(action: submitInput) {
                Image(systemName: "sparkles")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .disabled(inputPhrase.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func submitInput() {
        let trimmed = inputPhrase.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        suggestions = []
        submittedPhrase = trimmed
    }
}
