import SwiftUI
import SwiftData
import UIKit

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @Binding var navigationPath: NavigationPath
    @Binding var showSidebar: Bool
    @Binding var isDarkMode: Bool
    @Binding var showAgentCreation: Bool
    @Binding var showHelp: Bool
    @State private var messageText = ""
    
    init(viewModel: ChatViewModel, navigationPath: Binding<NavigationPath>, showSidebar: Binding<Bool>, isDarkMode: Binding<Bool>, showAgentCreation: Binding<Bool>, showHelp: Binding<Bool>) {
        self.viewModel = viewModel
        self._navigationPath = navigationPath
        self._showSidebar = showSidebar
        self._isDarkMode = isDarkMode
        self._showAgentCreation = showAgentCreation
        self._showHelp = showHelp
    }
    
    var body: some View {
        ZStack {
            // Background based on mode
            Group {
                if isDarkMode {
                    // Dark gradient background
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color(white: 0.1), // zinc-900 equivalent
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    // White background
                    Color.white
                }
            }
            .ignoresSafeArea()
            
            if viewModel.messages.isEmpty {
                // Centered layout when no messages
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Welcome message
                    WelcomeMessageView(isDarkMode: isDarkMode)
                        .padding(.bottom, 40)
                    
                    // Centered chatbox
                    MultimodalInputView(input: $messageText, isDarkMode: isDarkMode) {
                        sendMessage()
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            } else {
                // Scrollable layout when messages exist
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Messages area
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubble(message: message, isDarkMode: isDarkMode)
                                            .id(message.id)
                                    }
                                    
                                    if viewModel.isLoading {
                                        LoadingBubble(isDarkMode: isDarkMode)
                                    }
                                    
                                    if let error = viewModel.errorMessage {
                                        ErrorBubble(message: error, isDarkMode: isDarkMode)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { _, newValue in
                            if newValue {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    if let lastMessageId = viewModel.messages.last?.id {
                                        proxy.scrollTo(lastMessageId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Multimodal Input at bottom
                    MultimodalInputView(input: $messageText, isDarkMode: isDarkMode) {
                        sendMessage()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // Dismiss keyboard when opening sidebar
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSidebar = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                }
                .opacity(showSidebar ? 0 : 1)
                .allowsHitTesting(!showSidebar)
            }
            
            ToolbarItem(placement: .principal) {
                Button {
                    showAgentCreation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.themeAccent)
                }
                .opacity(showSidebar ? 0 : 1)
                .allowsHitTesting(!showSidebar)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Dismiss keyboard when opening help
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                }
                .opacity(showSidebar ? 0 : 1)
                .allowsHitTesting(!showSidebar)
            }
        }
        .onAppear {
            viewModel.loadMessages()
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !viewModel.isLoading else { return }
        
        messageText = ""
        
        Task {
            await viewModel.sendMessage(text)
        }
    }
}

// MARK: - Supporting Views
struct MessageBubble: View {
    let message: Message
    let isDarkMode: Bool
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser { Spacer(minLength: 40) }
            
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(message.isUser ? .white : (isDarkMode ? Color(white: 0.9) : Color(white: 0.2)))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.isUser 
                        ? Color.themeAccent // Orange from color palette
                        : (isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            message.isUser 
                                ? Color.clear
                                : (isDarkMode ? Color(white: 0.2) : Color(white: 0.8)),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !message.isUser { Spacer(minLength: 40) }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 1
            }
        }
    }
}

struct WelcomeMessageView: View {
    let isDarkMode: Bool
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo image
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, maxHeight: 200)
            
            Text("What can I do for you today?")
                .font(.system(size: 20))
                .foregroundColor(isDarkMode ? Color(white: 0.6) : Color(white: 0.4))
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                opacity = 1
            }
        }
    }
}

struct LoadingBubble: View {
    let isDarkMode: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Color.themeAccent)
                    .scaleEffect(0.8)
                Text("Thinking...")
                    .font(.system(size: 14))
                    .foregroundColor(isDarkMode ? Color(white: 0.6) : Color(white: 0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isDarkMode ? Color(white: 0.2) : Color(white: 0.8), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer(minLength: 40)
        }
    }
}

struct ErrorBubble: View {
    let message: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer(minLength: 40)
        }
    }
}

