import SwiftUI

/// Guided chat view for creating personalized AI-generated affirmations
struct AIAffirmationsChatView: View {
    let duration: StartAffirmationsView.AffirmationDuration
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
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
                
                // Chat content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            // Introduction
                            aiMessageBubble(
                                "Hi! I'm going to ask you a few questions to create personalized affirmations just for you. Take your time with each answer. 💫"
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
                    .onChange(of: allQuestionsAnswered) { _, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo("generate", anchor: .bottom)
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
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "2C2C2E"))
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [.clear, Color.museDeepNavy.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            HStack(alignment: .bottom, spacing: 12) {
                // Text input
                ZStack(alignment: .leading) {
                    if currentAnswer.isEmpty {
                        Text(questions[safe: currentQuestionIndex]?.placeholder ?? "Type your answer...")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.museLightGray.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextField("", text: $currentAnswer, axis: .vertical)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.museSoftWhite)
                        .lineLimit(1...5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .focused($isInputFocused)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.museDarkGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.museLightGray.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Send button
                Button(action: submitAnswer) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(currentAnswer.isEmpty ? .museLightGray : .museAccentBlue)
                }
                .disabled(currentAnswer.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
            .background(Color.museDeepNavy.opacity(0.9))
        }
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        VStack(spacing: 16) {
            aiMessageBubble("Perfect! I have everything I need. Ready to create your personalized affirmations?", icon: "sparkles")
            
            Button(action: generateAffirmations) {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Generate \(affirmationCount) Affirmations")
                        .font(.museButtonLarge())
                }
                .foregroundColor(.museSoftWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.museDarkGray.opacity(0.6))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .pulsingRainbowBorder()
                )
            }
            .padding(.horizontal, 20)
        }
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
                    // Increment Daily Usage Count (Entitlement Check)
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
        
        debugLog("🌟 Generating \(count) personalized affirmations...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugLog("🔴 Generation error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AffirmationGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Log raw response
            if let rawString = String(data: data, encoding: .utf8) {
                debugLog("🌟 Raw response: \(rawString)")
            }
            
            // Parse the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Parse the affirmations from the content
                    let affirmations = self.parseAffirmations(from: content)
                    
                    if affirmations.isEmpty {
                        completion(.failure(NSError(domain: "AffirmationGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse affirmations from response"])))
                    } else {
                        debugLog("🌟 Successfully generated \(affirmations.count) affirmations")
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
        // Clean up the content - remove markdown code blocks if present
        var cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to parse as JSON array
        if let data = cleanContent.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return array.map { text in
                Affirmation(text: text, category: "AI Generated")
            }
        }
        
        // Fallback: try to extract affirmations line by line
        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && ($0.hasPrefix("\"") || $0.hasPrefix("I ") || $0.hasPrefix("- ")) }
            .map { line -> String in
                // Clean up the line
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
