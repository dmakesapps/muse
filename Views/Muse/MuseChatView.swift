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
                    // Top section with logo and title
                    HStack(alignment: .top, spacing: 16) {
                        // Logo in top-left corner
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Muse")
                                .font(.museDisplayLarge())
                                .foregroundColor(.museSoftWhite)
                            
                            Text("Chat with your AI therapist")
                                .font(.museSubheadline())
                                .foregroundColor(.museLightGray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
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

