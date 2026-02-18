import SwiftUI
import Combine

class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    @Published var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        typealias KeyboardState = (isVisible: Bool, height: CGFloat)

        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> KeyboardState in
                let height = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
                return (true, height)
            }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> KeyboardState in
                return (false, 0)
            }

        willShow
            .merge(with: willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.isKeyboardVisible = state.isVisible
                self?.keyboardHeight = state.height
            }
            .store(in: &cancellables)
    }
}
