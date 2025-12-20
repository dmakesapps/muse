import SwiftUI

struct MuseChatView: View {
    @State private var isJournalPresented: Bool = false
    @State private var isChatHistoryPresented: Bool = false
    
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
                
                // Header - Chat History Button + Muse Title + Journal Button
                VStack {
                    ZStack {
                        // Centered Title
                        Text("Muse")
                            .font(.custom("Palatino-Bold", size: 28))
                            .foregroundColor(.museSoftWhite)
                        
                        // Left and Right buttons
                        HStack {
                            // Chat History Button - Left aligned
                            Button(action: {
                                isChatHistoryPresented = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.museDarkGray.opacity(0.8))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.museMediumGray.opacity(0.5), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.museGradientStart, Color.museGradientEnd],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Spacer()
                            
                            // Journal Button - Right aligned
                            Button(action: {
                                isJournalPresented = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.museDarkGray.opacity(0.8))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.museMediumGray.opacity(0.5), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "book.pages.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.museGradientStart, Color.museGradientEnd],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .zIndex(1) // Ensure header stays above chat content
            }
            .navigationBarHidden(true) // Hide the default navigation bar
            .fullScreenCover(isPresented: $isJournalPresented) {
                JournalView()
            }
            .fullScreenCover(isPresented: $isChatHistoryPresented) {
                ChatHistoryView()
            }
        }
    }
}

#Preview {
    MuseChatView()
}

