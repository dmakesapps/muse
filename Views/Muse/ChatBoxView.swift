import SwiftUI

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
    
    /// Convert to storable format
    func toStored() -> StoredChatMessage {
        StoredChatMessage(id: id, text: text, isUser: isUser, timestamp: timestamp)
    }
    
    /// Create from stored format
    static func from(_ stored: StoredChatMessage) -> ChatMessage {
        ChatMessage(id: stored.id, text: stored.text, isUser: stored.isUser, timestamp: stored.timestamp)
    }
}

struct ChatBoxView: View {
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping: Bool = false
    @State private var borderRotation: Double = 0 // For animated rainbow border
    @FocusState private var isInputFocused: Bool
    @StateObject private var speechRecognizer = SpeechRecognizer.shared
    @StateObject private var chatStorage = ChatStorageService.shared
    
    var body: some View {
        ZStack {
            // User requested "default dark" background
            Color.museDeepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Hidden generally, but we can add a speaker toggle top right if needed, or in the input bar)
                
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            if !messages.isEmpty {
                                // Add generous top padding to clear the journal button
                                Spacer().frame(height: 60)
                                
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
                                    .id("typing")
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
                    
                    // LEFT SPACER (for layout balance)
                    Spacer()
                        .frame(width: 44, height: 44)
                    
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
                        if !messageText.isEmpty && !speechRecognizer.isRecording {
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
                            Button(action: {
                                speechRecognizer.toggleRecording()
                            }) {
                                Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.fill")
                                    .font(.system(size: speechRecognizer.isRecording ? 28 : 20))
                                    .foregroundColor(speechRecognizer.isRecording ? .red : .museLightGray)
                                    .symbolEffect(.pulse, isActive: speechRecognizer.isRecording) // iOS 17+
                            }
                            .transition(.opacity)
                            .padding(.bottom, speechRecognizer.isRecording ? 8 : 10)
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

        }
        .onChange(of: speechRecognizer.transcript) { _, newTranscript in
            if speechRecognizer.isRecording && !newTranscript.isEmpty {
                messageText = newTranscript
            }
        }
        .onChange(of: speechRecognizer.isRecording) { _, isRecording in
            // Auto-send when recording stops and we have text
            if !isRecording && !messageText.isEmpty {
                sendMessage()
            }
        }
        .onDisappear {
            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            }
        }
        .onAppear {
            loadCurrentSession()
        }
        // Listen for session changes (e.g. "New Chat" from history)
        .onChange(of: chatStorage.currentSession?.id) { _, _ in
            loadCurrentSession()
        }
    }
    
    private func loadCurrentSession() {
        if let session = chatStorage.currentSession {
            withAnimation {
                messages = session.messages.map { ChatMessage.from($0) }
            }
        } else {
            withAnimation {
                messages = []
            }
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
        
        // Save user message to storage
        chatStorage.addMessage(userMessage.toStored())
        
        // Clear input
        messageText = ""
        isTyping = true
        
        // Call OpenRouter Chat Service (Gemini) with context from past conversations
        OpenRouterChatService.shared.sendMessage(history: messages, pastContext: chatStorage.getContextForAI()) { result in
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
                    
                    // Save AI message to storage
                    chatStorage.addMessage(aiMessage.toStored())
                    
                case .failure(let error):
                    print("Error calling OpenRouter: \(error.localizedDescription)")
                    
                    var errorText = "I'm having trouble connecting right now."
                    // Provide more specific feedback for common errors
                    if error.localizedDescription.contains("401") || error.localizedDescription.contains("User not found") {
                        errorText += "\n(Error: Invalid API Key - User not found)"
                    } else if error.localizedDescription.contains("429") {
                        errorText += "\n(Error: Model is currently busy/rate-limited. Please try again in a moment.)"
                    } else {
                        errorText += "\n(\(error.localizedDescription))"
                    }
                    
                    let errorMessage = ChatMessage(
                        text: errorText,
                        isUser: false,
                        timestamp: Date()
                    )
                    withAnimation {
                        messages.append(errorMessage)
                    }
                    // Note: We intentionally don't save error messages to storage
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

// MARK: - OpenRouter/Gemini Configuration
struct OpenRouterConfig {
    static let apiKey = "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"
    
    static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}

// MARK: - OpenRouter Chat Service (Gemini)
class OpenRouterChatService: ObservableObject {
    static let shared = OpenRouterChatService()
    
    // Using Google Gemini 2.0 Flash (001) as requested
    private let model = "google/gemini-2.0-flash-001"
    private let endpoint = "https://openrouter.ai/api/v1/chat/completions"
    
    // System prompt defines the persona
    private let systemPrompt = """
    You are Muse, a warm, empathetic, and highly intelligent AI therapist/companion.
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
    
    /// Send a message to OpenRouter (Gemini) and get a response
    /// - Parameters:
    ///   - history: Current conversation history
    ///   - pastContext: Optional context from previous conversations for memory
    ///   - completion: Callback with the result
    func sendMessage(history: [ChatMessage], pastContext: String = "", completion: @escaping (Result<String, Error>) -> Void) {
        guard OpenRouterConfig.isConfigured else {
            completion(.failure(NSError(domain: "OpenRouterChatService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])))
            return
        }
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "OpenRouterChatService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // 1. Build Dynamic System Prompt with past context
        let currentDate = Date().formatted(date: .long, time: .shortened)
        var dynamicSystemPrompt = """
        \(systemPrompt)
        
        Current Date and Time: \(currentDate)
        """
        
        // Add past conversation context if available
        if !pastContext.isEmpty {
            dynamicSystemPrompt += """
            
            
            \(pastContext)
            
            Use the above memories to provide more personalized and contextual support. Reference past conversations naturally when relevant.
            """
        }
        
        // 2. Flatten History & Sanitize
        // Strategy: Prepend System Prompt to the VERY FIRST User message to guarantee compatibility.
        // Some providers/models fail with "system" roles or consecutive user messages.
        
        var apiMessages: [[String: String]] = []
        
        var effectiveHistory = history
        
        // Setup initial content with system prompt
        let initialContent = """
        SYSTEM INSTRUCTION:
        \(dynamicSystemPrompt)
        
        USER MESSAGE:
        """
        
        // If history is empty, create a dummy user message to hold the system prompt (though usually not empty)
        if effectiveHistory.isEmpty {
           apiMessages.append(["role": "user", "content": initialContent])
        } else {
            // Prepend system prompt to the first message if it's a user message
            if var firstMsg = effectiveHistory.first, firstMsg.isUser {
                let combinedText = initialContent + "\n" + firstMsg.text
                // We construct a new dict for the API
                apiMessages.append(["role": "user", "content": combinedText])
                // Skip the first one in loop
                effectiveHistory.removeFirst()
            } else {
                // First message is assistant? Unusual but possible. Just add system as user message before it.
                apiMessages.append(["role": "user", "content": initialContent])
            }
            
            // Append the rest
            for msg in effectiveHistory {
                apiMessages.append([
                    "role": msg.isUser ? "user" : "assistant",
                    "content": msg.text
                ])
            }
        }
        
        // 3. Final Sanitize: Merge consecutive same-role messages
        if !apiMessages.isEmpty {
            var sanitized: [[String: String]] = []
            var currentMsg = apiMessages[0]
            
            for i in 1..<apiMessages.count {
                let nextMsg = apiMessages[i]
                if currentMsg["role"] == nextMsg["role"] {
                    // Merge content
                    let newContent = (currentMsg["content"] ?? "") + "\n\n" + (nextMsg["content"] ?? "")
                    currentMsg["content"] = newContent
                } else {
                    sanitized.append(currentMsg)
                    currentMsg = nextMsg
                }
            }
            sanitized.append(currentMsg)
            apiMessages = sanitized
        }
        
        // Construct the request body
        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(OpenRouterConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        // OpenRouter specific headers for ranking/stats
        request.addValue("Muse", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Muse App", forHTTPHeaderField: "X-Title")
        
        print("🟣 Muse Chat: Sending request to \(model)...")
        
        // CRITICAL: Set the request body! (This was missing before)
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("📝 Request Body: \(bodyString)")
            }
        } catch {
            print("🔴 Failed to serialize request body: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🔴 Muse Chat Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenRouterChatService", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Log raw response for debugging
            if let rawString = String(data: data, encoding: .utf8) {
                print("🟣 Raw Response: \(rawString)")
            }
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                // Try to parse error body for better description
                var errorDescription = "API Error: \(httpResponse.statusCode)"
                
                // Attempt to parse JSON error first
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorObj = errorJson["error"] as? [String: Any],
                   let message = errorObj["message"] as? String {
                    errorDescription += " - \(message)"
                } else {
                    // Fallback to raw string if JSON parsing fails (avoids "JSON parsing failed" error)
                    if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
                         // Truncate to avoid huge HTML dumps
                         let truncated = String(rawString.prefix(200))
                         errorDescription += " (Raw: \(truncated))"
                    } else {
                         errorDescription += " (Unknown error body)"
                    }
                }
                
                completion(.failure(NSError(domain: "OpenRouterChatService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])))
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    print("🟣 Muse Chat response received")
                    completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    print("🔴 Muse Chat: Failed to parse response structure")
                     if let rawString = String(data: data, encoding: .utf8) {
                        print("Raw Data was: \(rawString)")
                     }
                    completion(.failure(NSError(domain: "OpenRouterChatService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                print("JSON Parse Error: \(error)")
                completion(.failure(error)) // Use the actual serialization error
            }
        }.resume()
    }
}
