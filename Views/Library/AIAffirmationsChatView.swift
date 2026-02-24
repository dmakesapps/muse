import SwiftUI

/// Guided chat view for creating personalized AI-generated affirmations
struct AIAffirmationsChatView: View {
    let duration: StartAffirmationsView.AffirmationDuration
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    @AppStorage("hasConsentedToAIDataSharing") private var hasConsentedToAIDataSharing = false
    
    // Chat state
    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [String] = []
    @State private var currentAnswer = ""
    @State private var isTyping = false
    @State private var showingAnswer = false
    @State private var isGenerating = false
    @State private var generatedAffirmations: [Affirmation] = []
    @State private var showImmersiveView = false
    @State private var errorMessage: String?
    
    @FocusState private var isInputFocused: Bool
    
    // Guided questions
    private let questions = [
        GuidedQuestion(
            question: "What would you like to accomplish? Think about today, this week, or even this year.",
            placeholder: "Share your goals...",
            icon: "target"
        ),
        GuidedQuestion(
            question: "What's been holding you back from achieving these goals?",
            placeholder: "What obstacles do you face...",
            icon: "hand.raised"
        ),
        GuidedQuestion(
            question: "How would it feel to overcome these obstacles and achieve your goals?",
            placeholder: "Describe that feeling...",
            icon: "heart.fill"
        ),
        GuidedQuestion(
            question: "What strengths do you wish to embody more?",
            placeholder: "Confidence, patience, courage...",
            icon: "bolt.fill"
        ),
        GuidedQuestion(
            question: "Who do you want to become? Describe your ideal self.",
            placeholder: "The person you're growing into...",
            icon: "person.fill.checkmark"
        )
    ]
    
    private var allQuestionsAnswered: Bool {
        userAnswers.count >= questions.count
    }
    
    private var affirmationCount: Int {
        switch duration {
        case .oneMinute: return 5
        case .threeMinutes: return 12
        case .fiveMinutes: return 20
        case .tenMinutes: return 40
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if !hasConsentedToAIDataSharing {
                    privacyDisclosureView
                } else {
                    chatContent
                }
            }
        }
        .fullScreenCover(isPresented: $showImmersiveView) {
            ImmersiveAffirmationView(
                affirmations: generatedAffirmations,
                duration: duration,
                isAIGenerated: true,
                onComplete: {
                    showImmersiveView = false
                    onComplete()
                }
            )
        }
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Introduction
                        aiMessageBubble(
                            "Hi! I'm going to ask you a few questions to create personalized affirmations just for you. Muse uses AI (OpenAI & Google Gemini) to process your goals securely. Your data is protected and never used for training. Take your time with each answer. 💫"
                        )
                        .id("intro")
                        
                        // Questions and answers
                        ForEach(0..<min(currentQuestionIndex + 1, questions.count), id: \.self) { index in
                            questionAnswerPair(index: index)
                                .id("qa-\(index)")
                        }
                        
                        // Typing indicator
                        if isTyping {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .id("typing")
                        }
                        
                        // Generate button (after all questions answered)
                        if allQuestionsAnswered && !isGenerating && generatedAffirmations.isEmpty {
                            generateButton
                                .id("generate")
                        }
                        
                        // Loading state
                        if isGenerating {
                            generatingView
                                .id("generating")
                        }
                        
                        // Error message
                        if let error = errorMessage {
                            errorView(error)
                                .id("error")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
                .onChange(of: currentQuestionIndex) { _, _ in
                    withAnimation {
                        proxy.scrollTo("qa-\(currentQuestionIndex)", anchor: .bottom)
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
            
            // Input area (only show if not all questions answered)
            if !allQuestionsAnswered && !isGenerating {
                inputArea
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.museSoftWhite)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.museDarkGray))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Create Your Affirmations")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                Text("\(duration.rawValue) session • \(affirmationCount) affirmations")
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
            }
            
            Spacer()
            
            // Progress indicator
            Text("\(min(userAnswers.count + 1, questions.count))/\(questions.count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.museLightGray)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Question/Answer Pair
    @ViewBuilder
    private func questionAnswerPair(index: Int) -> some View {
        let question = questions[index]
        
        VStack(alignment: .leading, spacing: 12) {
            // AI Question
            aiMessageBubble(question.question, icon: question.icon)
            
            // User's Answer (if provided)
            if index < userAnswers.count {
                userMessageBubble(userAnswers[index])
                
                // Acknowledgment from AI (if not the last question)
                if index < questions.count - 1 {
                    aiMessageBubble(acknowledgments[index % acknowledgments.count])
                }
            }
        }
    }
    
    private let acknowledgments = [
        "That's wonderful! Understanding your goals is the first step. ✨",
        "Thank you for sharing that. Recognizing obstacles takes courage. 💪",
        "I can feel the power in that vision. Hold onto that feeling. 🌟",
        "Those are beautiful strengths to cultivate. 🌱",
        "What an inspiring vision of yourself! Let's create affirmations to help you become that person. 🦋"
    ]
    
    // MARK: - Message Bubbles
    private func aiMessageBubble(_ text: String, icon: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.museGradientStart, .museGradientEnd],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon ?? "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )
            
            Text(text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.museSoftWhite)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.museDarkGray.opacity(0.6))
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
            
            Spacer()
        }
    }
    
    private func userMessageBubble(_ text: String) -> some View {
        HStack {
            Spacer()
            
            Text(text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.museAccentBlue.opacity(0.8), .museAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 12) {
                TextField(questions[safe: currentQuestionIndex]?.placeholder ?? "Type your answer...", text: $currentAnswer)
                    .font(.museBodyMedium())
                    .foregroundColor(.museSoftWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.08))
                    )
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit(submitAnswer)
                
                Button(action: submitAnswer) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(currentAnswer.isEmpty ? .museLightGray : .museAccentBlue)
                }
                .disabled(currentAnswer.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: generateAffirmations) {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Personalized Affirmations")
                    .font(.museButtonMedium())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.museGradientStart, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .padding(.top, 20)
    }
    
    // MARK: - Generating View
    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.museAccentBlue)
            
            Text("Creating your personalized affirmations...")
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
            
            Text("This may take a moment")
                .font(.museCaption())
                .foregroundColor(.museLightGray.opacity(0.7))
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.museDarkGray.opacity(0.8))
        )
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
            
            Button(action: generateAffirmations) {
                Text("Try Again")
                    .font(.museButtonMedium())
                    .foregroundColor(.museSoftWhite)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.museAccentBlue)
                    )
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.museDarkGray.opacity(0.8))
        )
    }
    
    // MARK: - Actions
    private func submitAnswer() {
        guard !currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let answer = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        userAnswers.append(answer)
        currentAnswer = ""
        isInputFocused = false
        
        // Show typing indicator briefly before next question
        if currentQuestionIndex < questions.count - 1 {
            isTyping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isTyping = false
                withAnimation(.spring(response: 0.3)) {
                    currentQuestionIndex += 1
                }
            }
        }
    }
    
    private func generateAffirmations() {
        isGenerating = true
        errorMessage = nil
        
        // Build the prompt with user's answers
        let prompt = buildGenerationPrompt()
        
        // Call the AI service
        AffirmationGenerationService.shared.generateAffirmations(
            fromPrompt: prompt,
            count: affirmationCount
        ) { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let affirmations):
                    // Increment Daily Usage Count
                    EntitlementManager.shared.incrementAIGenerationCount()
                    
                    generatedAffirmations = affirmations
                    // Small delay then show immersive view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showImmersiveView = true
                    }
                    
                case .failure(let error):
                    errorMessage = "Failed to generate affirmations: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func buildGenerationPrompt() -> String {
        var prompt = """
        Based on the following personal insights, create \(affirmationCount) deeply personalized affirmations:
        
        """
        
        for (index, question) in questions.enumerated() {
            if index < userAnswers.count {
                prompt += """
                
                Q: \(question.question)
                A: \(userAnswers[index])
                
                """
            }
        }
        
        prompt += """
        
        Create affirmations that:
        - Directly address their goals and obstacles
        - Embody the strengths they want to develop
        - Reflect the person they want to become
        - Are written in first person ("I am...", "I...")
        - Are concise (under 15 words each) for spoken delivery
        - Feel personal and specific, not generic
        """
        
        return prompt
    }
    
    // MARK: - Privacy Disclosure
    private var privacyDisclosureView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.museAccentBlue)
                    .padding(.top, 40)
                
                Text("AI Privacy Notice")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.museSoftWhite)
                
                VStack(alignment: .leading, spacing: 20) {
                    disclosureRow(
                        icon: "cloud.fill",
                        title: "Data Transmission",
                        description: "Your answers will be sent to our AI partners (including OpenAI and Google Gemini via OpenRouter) to generate your affirmations."
                    )
                    
                    disclosureRow(
                        icon: "lock.shield.fill",
                        title: "No Personal Identity",
                        description: "We do not send your name, email, or any account details. Only the text responses you provide are shared."
                    )
                    
                    disclosureRow(
                        icon: "doc.text.fill",
                        title: "Not Used for Training",
                        description: "Our API agreements ensure your personal data is not used to train global AI models."
                    )
                    
                    disclosureRow(
                        icon: "eye.slash.fill",
                        title: "On-Device Storage",
                        description: "Once generated, your affirmations are stored locally on your device. We do not keep copies of your chat history on our servers."
                    )
                }
                .padding(.horizontal, 20)
                
                Text("By continuing, you consent to sharing your input with these third-party AI services for the purpose of creating your personalized content.")
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Button(action: {
                    withAnimation {
                        hasConsentedToAIDataSharing = true
                    }
                }) {
                    Text("I Consent & Continue")
                        .font(.museButtonMedium())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.museAccentBlue)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                Button(action: {
                    if let url = URL(string: "https://museapp.us/privacy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Read Full Privacy Policy")
                        .font(.museCaption())
                        .foregroundColor(.museAccentBlue)
                        .underline()
                }
                .padding(.bottom, 8)
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.museBodyMedium())
                        .foregroundColor(.museLightGray)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 10)
        }
    }
    
    private func disclosureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.museAccentBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.museLightGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Guided Question Model
struct GuidedQuestion {
    let question: String
    let placeholder: String
    let icon: String
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Affirmation Generation Service
class AffirmationGenerationService {
    static let shared = AffirmationGenerationService()
    
    private let endpoint = "https://openrouter.ai/api/v1/chat/completions"
    private let model = "google/gemini-2.0-flash-001"
    
    private init() {}
    
    func generateAffirmations(fromPrompt userContext: String, count: Int, completion: @escaping (Result<[Affirmation], Error>) -> Void) {
        
        let systemPrompt = """
        You are an expert affirmation creator. Your task is to generate deeply personalized, powerful affirmations based on the user's personal insights.
        
        Rules:
        1. Generate exactly \(count) affirmations
        2. Each affirmation should start with "I am" or "I" 
        3. Keep each affirmation under 15 words for easy spoken delivery
        4. Make them specific to the user's situation - avoid generic phrases
        5. Include affirmations that address their goals, overcome their obstacles, embody their desired strengths, and reflect who they want to become
        6. Make them emotionally resonant and empowering
        7. Return ONLY a JSON array of strings, nothing else. Example: ["I am capable of achieving my goals", "I embrace challenges as opportunities"]
        
        IMPORTANT: Return ONLY the JSON array, no markdown, no explanation, just the array.
        """
        
        let messages: [[String: String]] = [
            ["role": "user", "content": "SYSTEM: \(systemPrompt)\n\nUSER REQUEST:\n\(userContext)"]
        ]
        
        let body: [String: Any] = [
            "model": model,
            "messages": messages
        ]
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "AffirmationGeneration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(APIKeys.openRouter)", forHTTPHeaderField: "Authorization")
        request.addValue("Muse", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Muse App", forHTTPHeaderField: "X-Title")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        print("🌟 Generating \(count) personalized affirmations...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🔴 Generation error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AffirmationGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Parse the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    let affirmations = self.parseAffirmations(from: content)
                    
                    if affirmations.isEmpty {
                        completion(.failure(NSError(domain: "AffirmationGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse affirmations from response"])))
                    } else {
                        completion(.success(affirmations))
                    }
                } else {
                    completion(.failure(NSError(domain: "AffirmationGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parseAffirmations(from content: String) -> [Affirmation] {
        var cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let data = cleanContent.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return array.map { text in
                Affirmation(text: text, category: "AI Generated")
            }
        }
        
        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && ($0.hasPrefix("\"") || $0.hasPrefix("I ") || $0.hasPrefix("- ")) }
            .map { line -> String in
                var cleaned = line
                if cleaned.hasPrefix("- ") { cleaned = String(cleaned.dropFirst(2)) }
                if cleaned.hasPrefix("\"") { cleaned = String(cleaned.dropFirst()) }
                if cleaned.hasSuffix("\"") || cleaned.hasSuffix("\",") {
                    cleaned = String(cleaned.dropLast(cleaned.hasSuffix("\",") ? 2 : 1))
                }
                return cleaned
            }
        
        return lines.map { Affirmation(text: $0, category: "AI Generated") }
    }
}

#Preview {
    AIAffirmationsChatView(
        duration: .threeMinutes,
        onComplete: {}
    )
}
