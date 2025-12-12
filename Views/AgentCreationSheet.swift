import SwiftUI
import SwiftData

struct AgentCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Binding var isDarkMode: Bool
    
    @State private var agentName = ""
    @State private var personalityDescription = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var clarificationQuestions: String?
    @State private var clarificationAnswers = ""
    @State private var showClarificationStep = false
    @State private var isAskingQuestions = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case agentName, personalityDescription, clarificationAnswers
    }
    
    init(isDarkMode: Binding<Bool> = .constant(false)) {
        self._isDarkMode = isDarkMode
    }
    
    // Master prompt for creating notification agents (Eliza-style character-driven)
    private let masterPrompt = """
    You are creating a notification agent personality for a promise-keeping app. This agent will generate personalized notification messages (under 100 characters) that remind users about their promises.
    
    Your task is to create a STRONG, CHARACTER-DRIVEN system prompt similar to how Eliza creates distinct AI personalities. The system prompt must define the agent as a complete character with a consistent voice, not just a generic coach.
    
    CRITICAL REQUIREMENTS FOR THE SYSTEM PROMPT:
    1. Define the agent as a COMPLETE CHARACTER with a name, personality, and distinct voice
    2. Include 5-10 EXAMPLE NOTIFICATION MESSAGES that show exactly how this character speaks
    3. The examples must be in the character's exact voice - not generic, not wishy-washy
    4. Explicitly forbid generic phrases and provide alternatives in the character's voice
    5. Define the character's speech patterns, word choices, and communication style
    6. Make it clear this character ALWAYS speaks this way - consistency is key
    7. Each notification must be unique but always in character
    8. Notifications must relate to the specific promise
    
    ACCURACY REQUIREMENTS (if user mentioned a specific person or character):
    - If the user mentioned a real person, ensure you accurately represent their authentic speaking style, characteristic phrases, and communication patterns
    - If the user mentioned a fictional character, ensure you capture their distinct voice and mannerisms
    - If the user mentioned a character type (e.g., "military drill sergeant"), ensure the representation is accurate to that type
    - Use the user's description and clarification answers to ensure accuracy - do not make assumptions
    - If you're uncertain about a specific person, rely on what the user has described rather than guessing
    
    SYSTEM PROMPT STRUCTURE:
    The system prompt should follow this format:
    
    1. CHARACTER DEFINITION: Who is this agent? What's their name, personality, background?
    2. VOICE & STYLE: How do they speak? What words do they use? What's their tone?
    3. EXAMPLE MESSAGES: 5-10 example notifications showing their exact voice
    4. FORBIDDEN PHRASES: What they would NEVER say (generic phrases)
    5. REQUIREMENTS: Always be in character, always unique, always relate to the promise
    
    EXAMPLE SYSTEM PROMPT (David Goggins style):
    
    "You are David Goggins. You're intense, disciplined, and unrelenting. You don't accept excuses. You push people to be their absolute best. You use strong, direct language. You call out weakness. You demand excellence.
    
    YOUR VOICE:
    - Direct, commanding, intense
    - Use strong action words: push, demand, earn, fight, conquer
    - No soft language, no sugarcoating
    - Challenge people, don't just encourage
    - Reference hard work, discipline, mental toughness
    
    EXAMPLE NOTIFICATIONS (this is how you speak):
    - 'Time to earn it. No excuses. Get after it now.'
    - 'Weakness isn't an option. You made a promise. Keep it.'
    - 'Stop talking. Start doing. Your promise is waiting.'
    - 'The easy path? That's not you. Time to prove it.'
    - 'You said you'd do this. Now show yourself you meant it.'
    - 'Comfort zone? Leave it. Your promise demands more.'
    - 'No one's coming to save you. It's on you. Do it now.'
    - 'Excuses are for the weak. You're not weak. Prove it.'
    
    NEVER SAY (these are NOT you):
    - 'You've got this!' (too soft)
    - 'Keep going!' (too generic)
    - 'You can do it!' (too encouraging)
    - 'One day at a time' (too gentle)
    - Any generic motivational phrase
    
    REQUIREMENTS:
    - Every notification must be under 100 characters
    - Every notification must be in YOUR voice (David Goggins)
    - Every notification must be unique and different
    - Every notification must relate to the specific promise
    - Never be generic, soft, or wishy-washy
    - Always challenge, push, and demand excellence"
    
    Now create a system prompt for the agent described by the user. Follow the structure above. Include 5-10 example notifications that show exactly how this character speaks. Make it impossible for the agent to generate a generic message - the examples should make the voice crystal clear.
    
    Output format: AGENT_CREATE|systemPrompt|suggestedName
    """
    
    private var profile: UserProfile {
        profiles.first ?? UserProfile()
    }
    
    var body: some View {
        ZStack {
            // Background
            Group {
                if isDarkMode {
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color(white: 0.1),
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.white
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Text("Create Agent")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                    
                    Spacer()
                    
                    // Dark mode toggle button
                    Button {
                        isDarkMode.toggle()
                    } label: {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(white: 0.4))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill((isDarkMode ? Color.white : Color.black).opacity(0.1))
                            )
                    }
                    .padding(.trailing, 8)
                    
                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(white: 0.4))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill((isDarkMode ? Color.white : Color.black).opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        if !showClarificationStep {
                            // Initial input step
                            VStack(alignment: .leading, spacing: 16) {
                                // Agent Name Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Agent Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                                    
                                    TextField("Enter agent name", text: $agentName)
                                        .textInputAutocapitalization(.words)
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .font(.system(size: 16))
                                        .focused($focusedField, equals: .agentName)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                                        )
                                }
                                
                                // Personality Description Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Personality Description")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                                    
                                    TextField("Describe the personality...", text: $personalityDescription, axis: .vertical)
                                        .lineLimit(3...6)
                                        .textInputAutocapitalization(.sentences)
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .font(.system(size: 16))
                                        .focused($focusedField, equals: .personalityDescription)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                                        )
                                }
                                
                                // Help Text
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("How It Works")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                    
                                    Text("Describe the personality you want for your notification agent. For example: 'A tough love coach who uses emojis and short, direct messages' or 'A gentle, encouraging friend who uses longer, supportive messages'. If you mention a specific person or character type, we'll ask a few questions to make sure we get it right!")
                                        .font(.system(size: 13))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Clarification step
                            VStack(alignment: .leading, spacing: 16) {
                                // Questions Section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("A Few Questions")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                    
                                    if let questions = clarificationQuestions {
                                        Text(questions)
                                            .font(.system(size: 15))
                                            .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                                            )
                                    } else if isAskingQuestions {
                                        HStack {
                                            ProgressView()
                                                .tint(Color.themeAccent)
                                            Text("Generating questions...")
                                                .font(.system(size: 14))
                                                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                    }
                                    
                                    Text("We want to make sure we understand exactly what kind of agent you want, especially if you mentioned a specific person or character type.")
                                        .font(.system(size: 12))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                        .padding(.top, 4)
                                }
                                
                                // Answers Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Answers")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                                    
                                    TextField("Answer the questions above...", text: $clarificationAnswers, axis: .vertical)
                                        .lineLimit(4...8)
                                        .textInputAutocapitalization(.sentences)
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .font(.system(size: 16))
                                        .focused($focusedField, equals: .clarificationAnswers)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.9))
                                Text(errorMessage)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.9))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
                
                // Bottom Action Buttons
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((isDarkMode ? Color.white : Color.black).opacity(0.1))
                            )
                    }
                    
                    if !showClarificationStep {
                        Button {
                            askClarificationQuestions()
                        } label: {
                            if isAskingQuestions {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                    Text("Loading...")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.themeAccent)
                                )
                            } else {
                                Text("Next")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(agentName.isEmpty || personalityDescription.isEmpty ? Color.themeAccent.opacity(0.5) : Color.themeAccent)
                                    )
                            }
                        }
                        .disabled(agentName.isEmpty || personalityDescription.isEmpty || isAskingQuestions)
                    } else {
                        Button {
                            createAgent()
                        } label: {
                            if isCreating {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                    Text("Creating...")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.themeAccent)
                                )
                            } else {
                                Text("Create Agent")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(clarificationAnswers.isEmpty ? Color.themeAccent.opacity(0.5) : Color.themeAccent)
                                    )
                            }
                        }
                        .disabled(clarificationAnswers.isEmpty || isCreating)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .disabled(isCreating)
    }
    
    private func askClarificationQuestions() {
        guard !agentName.isEmpty, !personalityDescription.isEmpty else { return }
        
        // Set loading state immediately (synchronously)
        isAskingQuestions = true
        errorMessage = nil
        clarificationQuestions = nil
        
        Task {
            do {
                let questions = try await AICoachService.clarifyAgentDetails(
                    name: agentName,
                    personalityDescription: personalityDescription,
                    userProfile: profile
                )
                
                await MainActor.run {
                    clarificationQuestions = questions
                    showClarificationStep = true
                    isAskingQuestions = false
                }
            } catch {
                await MainActor.run {
                    // If clarification fails, proceed without it
                    errorMessage = "Could not generate clarification questions. Proceeding with your description."
                    showClarificationStep = true
                    isAskingQuestions = false
                }
            }
        }
    }
    
    private func createAgent() {
        guard !agentName.isEmpty, !personalityDescription.isEmpty else { return }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                // Use clarification answers if available
                let answers = clarificationAnswers.isEmpty ? nil : clarificationAnswers
                
                // Create agent using AICoachService
                let result = try await AICoachService.createNotificationAgent(
                    name: agentName,
                    personalityDescription: personalityDescription,
                    clarificationAnswers: answers,
                    masterPrompt: masterPrompt
                )
                
                // Use suggested name if provided, otherwise use user's name
                let finalName = result.suggestedName ?? agentName
                
                // Create the agent model
                let agent = NotificationAgent(
                    name: finalName,
                    personalityDescription: personalityDescription,
                    systemPrompt: result.systemPrompt
                )
                
                // Save to database
                modelContext.insert(agent)
                try modelContext.save()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create agent: \(error.localizedDescription)"
                    isCreating = false
                }
            }
        }
    }
}

