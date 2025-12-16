import SwiftUI

struct MuseChatView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                if let uiImage = UIImage(named: "backgroundjungle2") {
                    GeometryReader { geometry in
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .blur(radius: 30)
                            .overlay(Color.black.opacity(0.3))
                    }
                    .ignoresSafeArea()
                } else {
                    Color.museDeepNavy
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // Header removed
                    
                    // Chatbox - takes remaining space
                    ChatBoxView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true) // Hide the default navigation bar
        }
    }
}

#Preview {
    MuseChatView()
}

