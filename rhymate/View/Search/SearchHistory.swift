import SwiftUI

struct SearchHistoryList: View {
    @Binding var history: [SearchHistoryEntry]
    let destination: (String) -> RhymesView
    
    private let maxHistoryCount: Int = 4
    
    var body: some View {
        if history.isEmpty {
            EmptyView()
        } else {
            Section(header: Text("History")) {
                let suffixIndices = history.indices.prefix(maxHistoryCount)
                ForEach(Array(suffixIndices), id: \.self) { idx in
                    let entry = $history[idx]
                    NavigationLink(
                        destination: { destination(entry.input.wrappedValue) },
                        label: { Text("\(entry.input.wrappedValue)") }
                    )
                }
                if history.count > maxHistoryCount {
                    NavigationLink(
                        destination: SearchHistoryScreen(
                            history: $history,
                            destination: destination
                        ),
                        label: {Text("Show all")}
                    ).foregroundStyle(.accent)
                }
            }
        }
    }
}


struct SearchOverlayPreview: View {
    @State var searchHistory = [
        SearchHistoryEntry(
            input: "test",
            timestamp: Date().timeIntervalSinceReferenceDate)
    ]

    var body: some View{
        SearchHistoryList(
            history: $searchHistory,
            destination: { entry in
                RhymesView(word: entry)
            }
        )
    }
}

#Preview {
    SearchOverlayPreview()
}
