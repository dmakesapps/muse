import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showMuse = false
    @State private var showProgress = false
    
    var body: some View {
        FeedView(
            onProfileTap: {
                showProgress = true
            },
            onMessageTap: {
                showMuse = true
            }
        )
        .sheet(isPresented: $showMuse) {
            NavigationStack {
                MuseChatView()
            }
        }
        .sheet(isPresented: $showProgress) {
            NavigationStack {
                MuseProgressView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

