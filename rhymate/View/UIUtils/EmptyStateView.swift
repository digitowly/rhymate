import SwiftUI

struct EmptyStateView<Actions: View>: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let actions: Actions

    init(
        icon: String,
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        @ViewBuilder actions: () -> Actions
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text(title)
                .font(.title3.weight(.semibold))

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            actions
                .padding(.top, 8)
        }
        .padding(40)
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(
        icon: String,
        title: LocalizedStringKey,
        description: LocalizedStringKey
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actions = EmptyView()
    }
}
