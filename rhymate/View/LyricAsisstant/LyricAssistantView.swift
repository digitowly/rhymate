import SwiftUI

struct LyricAssistantView: View {
    @Binding var text: String;
    @Binding var favorites: FavoriteRhymes;
    var hasAutoSubmit = false
    
    @State private var height: CGFloat = 18
    @State private var corners: UIRectCorner = .allCorners
    
    @State private var searchText: String = ""
    @FocusState private var hasFocus: Bool
    @StateObject private var keyboard = KeyboardObserver()
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        VStack {
            ScrollView{
                if searchText.isEmpty {
                    LyricAssistantEmptyView()
                } else {
                    RhymesView(word: searchText, favorites: $favorites)
                }
            }
            Spacer()
            VStack {
                if text.split(separator: " ").count > 1 {
                    WordRecommendationView(
                        text: $text,
                        onSubmit: { word in
                            hideKeyboard()
                            searchText = word
                        })
                }
                HStack(alignment: .bottom) {
                    GrowingTextView(text: $text, height: $height)
                        .frame(height: height)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedCorners(radius: 24, corners: corners))
                    HStack() {
                        if text.split(separator: " ").count == 1 {
                            Button(action: {
                                 hideKeyboard()
                                 searchText = text;
                            }) {
                                Label("Send", systemImage: "arrow.up")
                                     .labelStyle(.iconOnly)
                                     .frame(width: 30, height: 30)
                             }
                             .buttonStyle(.borderedProminent)
                             .disabled(text.isEmpty)
                        }
                    }
                }.padding(.horizontal)
            }
            
            
        }
        .hideKeyboardOnTap()
        .onAppear() {
            if hasAutoSubmit && text.split(separator: " ").count == 1 {
                print("run auto submit")
                searchText = text
            }
        }
    }
}

private struct LyricAssistantPreview: View {
    @State var text: String = "Hello World"
    @State var favorites = FavoriteRhymesStorage().getFavoriteRhymes()
    
    var body: some View {
        LyricAssistantView(text: $text, favorites: $favorites)
    }
}

#Preview {
    LyricAssistantPreview()
}
