import SwiftUI

struct ChatBoxView: View {
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @FocusState private var isInputFocused: Bool
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    var body: some View {
        ZStack {
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if messages.isEmpty {
                            VStack(spacing: 12) {
                                Text("What can I do for you today?")
                                    .font(.museBodyLarge())
                                    .foregroundColor(.museLightGray)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Input area
            VStack(spacing: 12) {
                // Text input with send button
                HStack(alignment: .bottom, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.museDarkGray)
                            .rainbowBorder()
                        
                        if messageText.isEmpty {
                            Text("What would you like to do?")
                                .font(.museBodyMedium())
                                .foregroundColor(.museMediumGray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        
                        TextEditor(text: $messageText)
                            .font(.museBodyMedium())
                            .foregroundColor(.museSoftWhite)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 50, maxHeight: 120)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .focused($isInputFocused)
                    }
                    .frame(height: 60)
                    
                    // Send button
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(messageText.isEmpty ? .museMediumGray : .museAccentBlue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Quick action buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickActionButton(
                            icon: "book",
                            text: "Journal",
                            action: {
                                messageText = "Journal: "
                                isInputFocused = true
                            }
                        )
                        
                        QuickActionButton(
                            icon: "target",
                            text: "Goals",
                            action: {
                                messageText = "Goals: "
                                isInputFocused = true
                            }
                        )
                        
                        QuickActionButton(
                            icon: "plus.circle.fill",
                            text: "Generate +",
                            action: {
                                messageText = "Generate: "
                                isInputFocused = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
            }
            .background(
                Color.clear // Allow background from parent to show
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            text: messageText,
            isUser: true,
            timestamp: Date()
        )
        
        withAnimation {
            messages.append(userMessage)
        }
        
        // Clear input
        let sentText = messageText
        messageText = ""
        
        // Simulate AI response (replace with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let aiMessage = ChatMessage(
                text: "I received your message: \"\(sentText)\". This is a placeholder response. The Claude API integration will be added next.",
                isUser: false,
                timestamp: Date()
            )
            
            withAnimation {
                messages.append(aiMessage)
            }
        }
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.museBodyMedium())
                    .foregroundColor(message.isUser ? .museSoftWhite : .museSoftWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isUser ? Color.museAccentBlue : Color.museDarkGray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        message.isUser ? Color.museAccentBlue.opacity(0.3) : Color.museMediumGray.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.museSoftWhite)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.museMediumGray.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.museMediumGray, lineWidth: 1)
                            )
                    )
                
                Text(text)
                    .font(.museBodySmall())
                    .foregroundColor(.museSoftWhite)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.museMediumGray.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    ChatBoxView()
        .background(Color.museDeepNavy)
}

