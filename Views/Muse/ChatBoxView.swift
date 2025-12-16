import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct ChatBoxView: View {
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping: Bool = false
    @State private var borderRotation: Double = 0 // For animated rainbow border
    @FocusState private var isInputFocused: Bool
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    var body: some View {
        ZStack {
            // User requested "default dark" background
            Color.museDeepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            if !messages.isEmpty {
                                // Add generous top padding
                                Spacer().frame(height: 20)
                                
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if isTyping {
                                    HStack {
                                        TypingIndicator()
                                        Spacer()
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 140) // Clearance for input bar
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isTyping) { _, newValue in
                         if newValue {
                             withAnimation {
                                 proxy.scrollTo("typing", anchor: .bottom)
                             }
                         }
                    }
                }
            }
            .onTapGesture {
                isInputFocused = false
            }
            
            // Centered Empty State Content (Logo + Text)
            if messages.isEmpty && !isInputFocused {
                VStack(spacing: 16) {
                    Image("AppLogo") // Assuming "AppLogo" exists in assets
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("How are you feeling\ntoday?")
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundColor(.museSoftWhite)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .offset(y: -100) // Explicitly shift up to avoid overlap
                .transition(.opacity)
            }
            
            // Input Area
            VStack(spacing: 0) {
                Spacer()
                
                // The Animated Container
                HStack(alignment: .bottom, spacing: 0) {
                    
                    // LEFT ACCESSORY (Plus Button)
                    ZStack(alignment: .bottom) {
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.museLightGray)
                                .frame(width: 32, height: 32)
                                .background(Color.museMediumGray.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.bottom, 6)
                    }
                    .frame(width: 44, height: 44, alignment: .bottom)
                    
                    // CENTER: Input Text Area
                    ZStack(alignment: .leading) {
                        if messageText.isEmpty {
                            Text("Chat with Muse")
                                .font(.system(size: 17, weight: .regular, design: .rounded))
                                .foregroundColor(.museLightGray.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                        }
                        
                        TextField("", text: $messageText, axis: .vertical)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(.museSoftWhite)
                            .multilineTextAlignment(messageText.isEmpty ? .center : .leading)
                            .lineLimit(1...5)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 12)
                            .focused($isInputFocused)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // RIGHT ACCESSORY (Mic / Send)
                    ZStack(alignment: .bottom) {
                        if !messageText.isEmpty {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32)) 
                                    .foregroundColor(.museSoftWhite)
                                    .background(Color.museDeepNavy)
                                    .clipShape(Circle())
                            }
                            .transition(.scale.combined(with: .opacity))
                            .padding(.bottom, 6)
                        } else {
                            Button(action: {}) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.museLightGray)
                            }
                            .transition(.opacity)
                            .padding(.bottom, 10)
                        }
                    }
                    .frame(width: 44, height: 44, alignment: .bottom)
                }
                .padding(.horizontal, 6) 
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color.museDarkGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                                        center: .center,
                                        startAngle: .degrees(borderRotation),
                                        endAngle: .degrees(borderRotation + 360)
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                // Constraint width when centered/inactive
                .frame(width: (messages.isEmpty && !isInputFocused) ? 300 : nil)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .onAppear {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        borderRotation = 360
                    }
                }
            }
            .frame(maxWidth: .infinity)
            // Lowered position
            .padding(.bottom, (messages.isEmpty && !isInputFocused) ? UIScreen.main.bounds.height * 0.2 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isInputFocused)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: messages.isEmpty)
            // Gradient background only when active/bottom
            .background(
                Group {
                    if !messages.isEmpty || isInputFocused {
                        LinearGradient(
                            colors: [Color.museDeepNavy.opacity(0), Color.museDeepNavy],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .ignoresSafeArea()
                    }
                }
            )
        }
    }
    
    private func setQuickAction(_ text: String) {
        messageText = text
        isInputFocused = true
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
        messageText = ""
        isTyping = true
        
        // Call Claude Service
        ClaudeService.shared.sendMessage(history: messages) { result in
            DispatchQueue.main.async {
                isTyping = false
                switch result {
                case .success(let responseText):
                    let aiMessage = ChatMessage(
                        text: responseText,
                        isUser: false,
                        timestamp: Date()
                    )
                    
                    withAnimation {
                        messages.append(aiMessage)
                    }
                    
                case .failure(let error):
                    print("Error calling Claude: \(error.localizedDescription)")
                    let errorMessage = ChatMessage(
                        text: "I'm having trouble connecting right now. Please try again.",
                        isUser: false,
                        timestamp: Date()
                    )
                    withAnimation {
                        messages.append(errorMessage)
                    }
                }
            }
        }
    }
}



struct QuickActionPill: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(text)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            } else {
                // AI Avatar
                Circle()
                    .fill(
                        LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white) // Always white text for contrast
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.isUser {
                                // User: Solid Gradientish color or subtle dark gray
                                Color(hex: "2C2C2E")
                            } else {
                                // AI: Glassmorphism / Transparent feel
                                Rectangle()
                                    .fill(Color.clear) // Transparent background
                            }
                        }
                    )
                    .clipShape(
                        RoundedCorner(
                            radius: 20,
                            corners: message.isUser 
                                ? [.topLeft, .topRight, .bottomLeft] 
                                : [.topRight, .bottomLeft, .bottomRight]
                        )
                    )
                    // Add border for user messages to make them pop against dark bg
                    .overlay(
                        Group {
                            if message.isUser {
                                RoundedCorner(
                                    radius: 20,
                                    corners: [.topLeft, .topRight, .bottomLeft]
                                )
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            }
                        }
                    )
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

// Custom Shape for specific corner rounding
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatBoxView()
        .background(Color.museDeepNavy)
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var numberOfDots = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.museMediumGray)
                    .frame(width: 8, height: 8)
                    .opacity(numberOfDots == index ? 1 : 0.4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.museDarkGray)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                numberOfDots = 2
            }
            // More complex animation if needed, but simple opacity pulse works
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation {
                    numberOfDots = (numberOfDots + 1) % 3
                }
            }
        }
    }
}

// MARK: - Claude Service Configuration
/// Configuration for Anthropic's Claude API
struct ClaudeConfig {
    // Replace with your Claude API key
    static let apiKey = "YOUR_CLAUDE_API_KEY_HERE"
    
    /// Check if a valid API key is configured
    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != "YOUR_CLAUDE_API_KEY_HERE"
    }
}

// MARK: - Claude Service
class ClaudeService: ObservableObject {
    static let shared = ClaudeService()
    
    // Use the latest 3.5 Haiku model (cheapest and fastest)
    private let model = "claude-3-5-haiku-20241022"
    private let endpoint = "https://api.anthropic.com/v1/messages"
    
    // System prompt defines the persona
    private let systemPrompt = """
    You are Muse, a warm, empathetic, and highly intelligent AI therapist. 
    Your goal is to help the user navigate their thoughts and feelings with compassion and insight. 
    
    Key traits:
    - Listen deeply and validate the user's feelings first.
    - Ask thoughtful, clarifying questions to explore deeper meaning.
    - Offer gentle guidance rather than strict "advice" or potential diagnosis.
    - Maintain a conversational, human-like tone. Avoid robotic lists or generic platitudes.
    - If the user discusses self-harm or severe crisis, gently encourage professional help while remaining supportive.
    
    Your responses should be concise but meaningful.
    """
    
    private init() {}
    
    /// Send a message to Claude and get a response
    func sendMessage(history: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        guard ClaudeConfig.isConfigured else {
            completion(.failure(NSError(domain: "ClaudeService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])))
            return
        }
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "ClaudeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Convert chat history to Claude's format
        let apiMessages = history.map { msg -> [String: Any] in
            return [
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.text
            ]
        }
        
        // Construct the request body
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": apiMessages
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(ClaudeConfig.apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        print("🟣 Muse Chat: Sending request to Claude...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🔴 Muse Chat Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "ClaudeService", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("🔴 Muse Chat API Error: \(errorJson)")
                }
                
                completion(.failure(NSError(domain: "ClaudeService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(httpResponse.statusCode)"])))
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let contentArray = json["content"] as? [[String: Any]],
                   let firstBlock = contentArray.first,
                   let text = firstBlock["text"] as? String {
                    
                    print("🟣 Muse Chat response received")
                    completion(.success(text))
                } else {
                    print("🔴 Muse Chat: Failed to parse response structure")
                    completion(.failure(NSError(domain: "ClaudeService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
