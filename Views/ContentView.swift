import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Library
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(0)
            
            // Tab 2: Discover
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "lightbulb.fill")
                }
                .tag(1)
            
            // Tab 3: Muse
            MuseChatView()
                .tabItem {
                    Label("Muse", systemImage: "message.fill")
                }
                .tag(2)
            
            // Tab 4: Progress
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .accentColor(.museAccentBlue)
        .preferredColorScheme(.dark)
    }
}

