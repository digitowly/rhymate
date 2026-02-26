import SwiftUI

struct SettingsView: View {
    @AppStorage(AIFeatures.defaultsKey) private var aiEnabled: Bool = true

    var body: some View {
        NavigationStack {
            List {
                if AIFeatures.isHardwareAvailable {
                    Section {
                        Toggle(isOn: $aiEnabled) {
                            Label("AI Features", systemImage: "sparkles")
                        }
                    } header: {
                        Text("Experimental")
                    } footer: {
                        Text("Enables AI-powered rhyme suggestions and Inspire. Requires Apple Intelligence.")
                    }
                }
                NavigationLink(destination: AboutScreen()) {
                    Text("About")
                }
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
}

#Preview {
    SettingsView()
}
