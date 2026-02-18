import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    let release: WhatsNewRelease

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("What's New")
                .font(.largeTitle.bold())
                .padding(.vertical, 32)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(release.features.enumerated()), id: \.offset) { _, feature in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(.accent)
                                .frame(width: 44, height: 44)
                                .background(.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(.title3.weight(.semibold))
                                    .padding(.bottom, 4)
                                Text(feature.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    WhatsNewView(release: WhatsNewContent.releases.first!)
}
