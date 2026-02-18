import SwiftUI

struct AboutScreen: View {
    @State private var showWhatsNew = false

    var body: some View {
        Form {
            Section {
                Text("Rhymate uses the Datamuse API to find rhyming words and Wiktionary for word definitions.")
                Link("Datamuse API", destination: URL(string: "https://www.datamuse.com/api/")!)
                Link("Wiktionary API", destination: URL(string: "https://en.wiktionary.org/w/api.php")!)
            }

            if let release = WhatsNewContent.releases.last {
                Section {
                    Button("What's New") {
                        showWhatsNew = true
                    }
                }
                .sheet(isPresented: $showWhatsNew) {
                    WhatsNewView(release: release)
                }
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    AboutScreen()
}
