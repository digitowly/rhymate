import SwiftUI

struct WordRecommendationView: View {
    @Binding var text: String
    var onSubmit: (String) -> Void;
    
    @State private var textParts: [String] = []
    
    private func setTextParts() {
        textParts = text.split(separator: " ").map{ s in
            return Formatter.normalize(String(s))
        }
    }
    
    var body: some View {
        ScrollView(.horizontal){
            HStack{
                ForEach(textParts, id: \.self) { part in
                    Button(part) {
                        onSubmit(part)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .scrollIndicators(.visible, axes: .horizontal)
        .onAppear() { setTextParts() }
        .onChange(of: text) { t in
            setTextParts()
        }
    }
}

#Preview {
//    WordRecommendationView()
}
