import SwiftUI

struct LyricAssistantEmptyView: View {
    var body: some View {
        EmptyStateView(
            icon: "character.book.closed.fill",
            title: "No rhymes yet",
            description: "Type a word or phrase below to get started"
        )
    }
}

#Preview {
    LyricAssistantEmptyView()
}
