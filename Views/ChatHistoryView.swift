import SwiftUI

/// A view showing the user's chat history with Muse

struct ChatHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatStorage = ChatStorageService.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.museDeepNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                ZStack {
                    // Centered Title
                    Text("Conversations")
                        .font(.custom("Palatino-Bold", size: 24))
                        .foregroundColor(.museSoftWhite)
                    
                    // Buttons
                    HStack {
                        // New Chat Button (Left)
                        Button(action: {
                            chatStorage.startNewSession()
                            dismiss()
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.museAccentBlue)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        // Close Button (Right)
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.museLightGray)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(Color.museDeepNavy)
                
                // Content
                if chatStorage.chatSessions.isEmpty {
                    emptyStateView
                } else {
                    chatSessionsList
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Decorative icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.museGradientStart.opacity(0.3), Color.museGradientEnd.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.museGradientStart, Color.museGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Conversations Yet")
                    .font(.museDisplaySmall())
                    .foregroundColor(.museSoftWhite)
                
                Text("Start chatting with Muse and your\nconversations will be saved here.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Start a new chat button
            Button(action: {
                chatStorage.startNewSession()
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.bubble.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Start a Conversation")
                        .font(.museButtonMedium())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.museGradientStart, Color.museGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.museGradientStart.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var chatSessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(chatStorage.chatSessions) { session in
                    ChatSessionCard(
                        session: session,
                        isCurrentSession: session.id == chatStorage.currentSession?.id
                    ) {
                        // Load this session and dismiss
                        chatStorage.loadSession(session)
                        dismiss()
                    } onDelete: {
                        withAnimation {
                            chatStorage.deleteSession(session)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Chat Session Card

struct ChatSessionCard: View {
    let session: StoredChatSession
    let isCurrentSession: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Chat icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.museGradientStart.opacity(0.2), Color.museGradientEnd.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isCurrentSession ? "bubble.left.and.bubble.right.fill" : "bubble.left.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.museGradientStart, Color.museGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(session.title)
                            .font(.museHeadline())
                            .foregroundColor(.museSoftWhite)
                            .lineLimit(1)
                        
                        if isCurrentSession {
                            Text("Active")
                                .font(.museCaption())
                                .foregroundColor(.museSuccessGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.museSuccessGreen.opacity(0.2))
                                )
                        }
                        
                        Spacer()
                        
                        Text(session.updatedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.museCaption())
                            .foregroundColor(.museLightGray)
                    }
                    
                    Text(session.lastMessage)
                        .font(.museBodySmall())
                        .foregroundColor(.museLightGray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(session.messageCount) messages")
                        .font(.museCaption())
                        .foregroundColor(.museMediumGray)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.museMediumGray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCurrentSession ? Color.museDarkGray.opacity(0.8) : Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isCurrentSession ? Color.museGradientStart.opacity(0.5) : Color.museMediumGray.opacity(0.3), lineWidth: isCurrentSession ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Conversation", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ChatHistoryView()
}
