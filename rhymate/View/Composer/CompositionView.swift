import SwiftUI
import SwiftData

struct CompositionView: View {
    @Bindable var composition: Composition
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AIFeatures.defaultsKey) private var aiEnabled: Bool = true
    @State var isMoveSheetVisible: Bool = false
    @State private var isAssistantVisible = false
    @State private var isBuddyVisible = false
    @State private var selectedWord = ""
    @State private var dragOffset: CGFloat = 0
    @State private var assistantSearchTerm = ""

    private var showBuddyFeature: Bool { aiEnabled && AIFeatures.isHardwareAvailable }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading) {
                    Spacer(minLength: 32)
                    ComposeEditor(
                        key: composition.id.uuidString,
                        text: Binding(
                            get: { composition.content },
                            set: { composition.content = $0 }
                        ),
                        onChange: { composition.updatedAt = Date.now },
                        isAssistantVisible: $isAssistantVisible,
                        isBuddyVisible: $isBuddyVisible,
                        selectedWord: $selectedWord
                    )
                }
                .padding(.horizontal)
            }
            .toolbar {
                if horizontalSizeClass == .regular {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation {
                                if columnVisibility == .detailOnly {
                                    columnVisibility = .all
                                } else {
                                    columnVisibility = .detailOnly
                                }
                            }
                        } label: {
                            Image(systemName: columnVisibility == .detailOnly
                                  ? "arrow.down.right.and.arrow.up.left"
                                  : "arrow.up.left.and.arrow.down.right")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            isMoveSheetVisible.toggle()
                        }) {
                            Label("Move", systemImage: "arrow.forward.folder.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $isMoveSheetVisible) {
                NavigationStack {
                    CompositionMoveView(
                        composition: composition,
                        onPress: { isMoveSheetVisible.toggle() }
                    )
                }
            }
            .navigationTitle(composition.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            #if DEBUG
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-openAssistantForSnapshot") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        selectedWord = "Rain"
                        withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                            isAssistantVisible = true
                        }
                    }
                }
            }
            #endif

            if isAssistantVisible {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeAssistant()
                    }

                assistantPanel
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom))
            }

            if showBuddyFeature && isBuddyVisible {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeBuddy()
                    }

                buddyPanel
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = UIScreen.main.bounds.height
            let newHeight = max(screenHeight - frame.origin.y, 0)

            if newHeight == 0 {
                if isAssistantVisible {
                    withAnimation(.spring(duration: 0.3, bounce: 0.05)) {
                        isAssistantVisible = false
                    }
                }
                if showBuddyFeature && isBuddyVisible {
                    withAnimation(.spring(duration: 0.3, bounce: 0.05)) {
                        isBuddyVisible = false
                    }
                }
            }
        }
    }

    private func closeAssistant() {
        withAnimation(.spring(duration: 0.3, bounce: 0.05)) {
            isAssistantVisible = false
        }
    }

    private func closeBuddy() {
        withAnimation(.spring(duration: 0.3, bounce: 0.05)) {
            isBuddyVisible = false
        }
    }

    private var assistantPanel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            HStack {
                Text(assistantSearchTerm.isEmpty ? "Rhymes" : assistantSearchTerm)
                    .font(.headline)
                Spacer()
                Button {
                    closeAssistant()
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            LyricAssistantView(
                text: $selectedWord,
                hasAutoSubmit: true,
                onSearchTermChange: { term in
                    assistantSearchTerm = term
                }
            )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = ComposerLogic.resistedDragOffset(translation: value.translation.height)
                }
                .onEnded { value in
                    if ComposerLogic.shouldDismiss(translation: value.translation.height) {
                        closeAssistant()
                        dragOffset = 0
                    } else {
                        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    private var buddyPanel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            HStack {
                Label("Inspire", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Button {
                    closeBuddy()
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            LyricBuddyView(initialPhrase: selectedWord)
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = ComposerLogic.resistedDragOffset(translation: value.translation.height)
                }
                .onEnded { value in
                    if ComposerLogic.shouldDismiss(translation: value.translation.height) {
                        closeBuddy()
                        dragOffset = 0
                    } else {
                        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}
