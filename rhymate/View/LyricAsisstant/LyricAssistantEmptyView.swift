import SwiftUI

struct LyricAssistantEmptyView: View {
    var body: some View {
        Image("rhymate")
            .font(.system(size: 72))
            .padding(16)
            .padding(.top, 32)
        
        Text("No rhymes yet")
            .font(.headline)
            .foregroundColor(.primary)

        Text("Type a word or phrase below to get started")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }
}

#Preview {
    LyricAssistantEmptyView()
}
