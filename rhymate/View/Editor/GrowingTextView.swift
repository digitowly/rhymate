import SwiftUI

struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.textContainer.widthTracksTextView = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        DispatchQueue.main.async {
            let fittingSize = CGSize(width: uiView.bounds.width > 0 ? uiView.bounds.width : 300, height: .infinity)
            let newSize = uiView.sizeThatFits(fittingSize)
            if abs(newSize.height - height) > 1 {
                self.height = max(newSize.height, 18) // minimum height
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $height)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var height: CGFloat

        init(text: Binding<String>, height: Binding<CGFloat>) {
            _text = text
            _height = height
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text

            let fittingSize = CGSize(width: textView.bounds.width > 0 ? textView.bounds.width : 300, height: .infinity)
            let newSize = textView.sizeThatFits(fittingSize)
            if abs(newSize.height - height) > 1 {
                DispatchQueue.main.async {
                    self.height = max(newSize.height, 18)
                }
            }
        }
    }
}
