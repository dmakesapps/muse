import Foundation

// MARK: - Muse Agent Service

/// Central service for the Muse AI agent - handles prompting, context injection, and crisis detection
@MainActor
class MuseAgentService {
    static let shared = MuseAgentService()
    
    private let userProfile = MuseUserProfileService.shared
    private let progressService = ProgressService.shared
    
    private init() {}
    
    // MARK: - Crisis Detection
    
    /// Keywords that indicate potential crisis - must provide resources immediately
    private let crisisKeywords = [
        "suicide", "kill myself", "end my life", "want to die",
        "self-harm", "hurt myself", "cutting", "don't want to live",
        "end it all", "no reason to live", "better off dead"
    ]
    
    /// Check if a message contains crisis indicators
    func detectCrisis(in message: String) -> Bool {
        let lowercased = message.lowercased()
        return crisisKeywords.contains { lowercased.contains($0) }
    }
    
    /// Get crisis response that must be prepended to AI response
    func getCrisisResponse() -> String {
        return """
        I hear that you're in a lot of pain right now. Your life matters, and there are people who can help immediately.
        
        🆘 **Crisis Resources:**
        • National Suicide Prevention Lifeline: **988** (US)
        • Crisis Text Line: Text **HOME** to **741741**
        • International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/
        
        Please reach out to one of these services right now. I'm here with you, but trained crisis counselors can provide the immediate support you need.
        
        """
    }
    
    // MARK: - Feature Detection (Deep Linking)
    
    /// Keywords that suggest user wants to start a practice
    struct FeatureIntent {
        let feature: AppFeature
        let confidence: Double
    }
    
    enum AppFeature: String {
        case breathwork = "breathwork"
        case affirmations = "affirmations"
        case frequencies = "frequencies"
        case manifestation = "manifestation"
        case progress = "progress"
    }
    
    /// Detect if user is asking to start a feature
    func detectFeatureIntent(in message: String) -> FeatureIntent? {
        let lowercased = message.lowercased()
        
        // Breathwork triggers
        let breathworkTriggers = ["breathe", "breathing", "breathwork", "calm me", "anxious", "panic", "stressed", "relax"]
        if breathworkTriggers.contains(where: { lowercased.contains($0) }) {
            return FeatureIntent(feature: .breathwork, confidence: 0.7)
        }
        
        // Affirmation triggers
        let affirmationTriggers = ["affirmation", "affirm", "positive thought", "mantra", "self-talk"]
        if affirmationTriggers.contains(where: { lowercased.contains($0) }) {
            return FeatureIntent(feature: .affirmations, confidence: 0.8)
        }
        
        // Frequency triggers
        let frequencyTriggers = ["frequency", "frequencies", "binaural", "sound", "hz", "hertz", "focus music", "meditation music"]
        if frequencyTriggers.contains(where: { lowercased.contains($0) }) {
            return FeatureIntent(feature: .frequencies, confidence: 0.8)
        }
        
        // Manifestation triggers
        let manifestationTriggers = ["manifest", "visualization", "vision", "attract", "law of attraction"]
        if manifestationTriggers.contains(where: { lowercased.contains($0) }) {
            return FeatureIntent(feature: .manifestation, confidence: 0.7)
        }
        
        // Progress triggers
        let progressTriggers = ["my progress", "streak", "how am i doing", "my stats"]
        if progressTriggers.contains(where: { lowercased.contains($0) }) {
            return FeatureIntent(feature: .progress, confidence: 0.8)
        }
        
        return nil
    }
    
    // MARK: - System Prompt Generation
    
    /// Build the core system prompt (always sent)
    func buildCoreSystemPrompt() -> String {
        return """
        You are Muse, an empathetic mindset transformation guide and neuroplasticity expert. Your purpose is to help users rewire their brains through scientifically-backed positive psychology, affirmations, breathwork, and vibrational frequency practices.

        CORE PRINCIPLES:
        • Lead with empathy and validation before offering solutions
        • Ground all suggestions in neuroscience and positive psychology
        • Personalize every interaction based on user history and emotional state
        • Celebrate progress, no matter how small
        • Never be preachy or overly prescriptive—empower user autonomy
        • Balance spiritual concepts with practical, evidence-based approaches
        • Maintain hope while acknowledging challenges authentically

        KNOWLEDGE DOMAINS:
        • Neuroplasticity and habit formation (Hebbian learning, neural pathways)
        • Cognitive restructuring and reframing techniques
        • Breathwork physiology (parasympathetic activation, HRV optimization)
        • Manifestation psychology (RAS activation, goal priming)
        • Frequency therapy and binaural beats (alpha, theta, delta states)
        • Positive psychology (gratitude, growth mindset, self-compassion)
        • Behavioral change models (Tiny Habits, implementation intentions)

        RESPONSE STYLE:
        • Warm and conversational—never robotic or clinical
        • Ask one thoughtful question at a time
        • Mirror the user's emotional energy and language
        • Keep responses concise (2-4 paragraphs) unless depth is requested
        • Use occasional emojis sparingly for warmth, not excess

        EMPATHY FIRST:
        When user expresses struggle, difficulty, or negative emotions:
        1. VALIDATE: "It sounds like you're feeling..." / "That's completely understandable"
        2. INQUIRE: Ask one clarifying question to understand deeper
        3. BRIDGE: Offer a relevant tool (breathwork, affirmation, frequency)
        4. EMPOWER: Remind them of their capacity and suggest one small action

        APP INTEGRATION:
        You can suggest these Muse features when relevant:
        • Breathwork sessions (for anxiety, stress, grounding)
        • Affirmation practice (for mindset shifts, confidence, self-worth)
        • Frequency therapy (for focus, relaxation, sleep, healing)
        • Manifestation work (for goal clarity, vision building)
        
        When suggesting a feature, frame it as an invitation: "Would you like to try a breathing exercise right now?" rather than a command.

        SAFETY:
        If user mentions self-harm, suicide, or severe crisis:
        1. Immediately provide crisis resources (988 Lifeline, Crisis Text Line)
        2. Express genuine care for their wellbeing
        3. Encourage professional support
        4. Do NOT attempt to provide therapy for clinical crisis
        """
    }
    
    /// Build dynamic user context (injected per request)
    func buildUserContext() -> String {
        let profile = userProfile.profile
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let currentDateTime = dateFormatter.string(from: Date())
        
        var context = """
        CURRENT CONTEXT:
        Date/Time: \(currentDateTime)
        Days Active (Streak): \(progressService.currentStreak)
        Total Sessions Completed: \(progressService.totalSessions)
        Sessions Today: \(progressService.todaySessionCount)
        """
        
        if let goal = profile.primaryGoal {
            context += "\nPrimary Goal: \(goal)"
        }
        
        if !profile.lifeDomains.isEmpty {
            let domains = profile.lifeDomains.map { $0.rawValue }.joined(separator: ", ")
            context += "\nLife Focus Areas: \(domains)"
        }
        
        if let modality = profile.preferredModality {
            context += "\nPreferred Practice: \(modality.rawValue)"
        }
        
        if let challenge = profile.currentChallenge {
            context += "\nCurrent Challenge: \(challenge)"
        }
        
        if !profile.recentMilestones.isEmpty {
            let milestones = profile.recentMilestones.suffix(3).joined(separator: "; ")
            context += "\nRecent Milestones: \(milestones)"
        }
        
        // Add orientation for response styling
        switch profile.spiritualOrientation {
        case .secular:
            context += "\n\nNote: User prefers secular/scientific language. Frame everything in neuroscience and psychology terms."
        case .spiritual:
            context += "\n\nNote: User is spiritually open. Feel free to include energy, universe, alignment language."
        case .blended:
            context += "\n\nNote: User appreciates both science and spirituality. Integrate both naturally."
        }
        
        switch profile.challengeLevel {
        case .gentle:
            context += "\nAffirmation style: Gentle, believable, comforting."
        case .moderate:
            context += "\nAffirmation style: Moderately stretching, growth-oriented."
        case .bold:
            context += "\nAffirmation style: Bold, identity-level, confronting limiting beliefs."
        }
        
        return context
    }
    
    /// Build the complete system prompt with all context
    func buildCompleteSystemPrompt(pastContext: String = "") -> String {
        var prompt = buildCoreSystemPrompt()
        prompt += "\n\n" + buildUserContext()
        
        if !pastContext.isEmpty {
            prompt += "\n\n" + pastContext
            prompt += "\n\nUse the above memories to provide personalized, contextual support. Reference past conversations naturally when relevant."
        }
        
        return prompt
    }
    
    // MARK: - Feature-Specific Prompt Modules
    
    /// Get additional prompting for breathwork guidance
    func getBreathworkModule() -> String {
        return """
        
        BREATHWORK GUIDANCE:
        When guiding breathwork, recommend based on user state:
        
        FOR ANXIETY/STRESS → CALM:
        • Box Breathing (4-4-4-4): "Breathe in 4, hold 4, out 4, hold 4"
        • Extended Exhale (4-7-8): "Your exhale is your calm button"
        
        FOR LOW ENERGY → ENERGIZED:
        • Breath of Fire: Rapid diaphragmatic breaths
        • Bellows Breath: Powerful inhales/exhales
        
        FOR MENTAL CLARITY:
        • Alternate Nostril: Balances brain hemispheres
        
        Always offer timing: "Would you like 2 minutes, 5 minutes, or longer?"
        Include safety: "If you feel dizzy, return to normal breathing."
        """
    }
    
    /// Get additional prompting for affirmation generation
    func getAffirmationModule() -> String {
        return """
        
        AFFIRMATION DESIGN PRINCIPLES:
        When creating affirmations:
        1. Present tense, first person ("I am", "I have", "I create")
        2. Emotionally activating (engage feeling, not just cognition)
        3. Specific enough to be meaningful, general enough to be flexible
        4. Bridge current state to desired state
        
        FOR HIGH RESISTANCE: Use "I am becoming" or "I am learning to" (reduces cognitive dissonance)
        FOR EMOTIONAL WOUNDS: Include self-compassion elements
        FOR IDENTITY SHIFTS: Frame as uncovering true self, not creating new self
        
        Generate 3-5 affirmations when asked, with brief explanation of why each works.
        """
    }
    
    /// Get additional prompting for manifestation guidance
    func getManifestationModule() -> String {
        return """
        
        MANIFESTATION GUIDANCE:
        Ground manifestation in science:
        • Reticular Activating System (RAS): Brain's filter notices aligned opportunities
        • Neuroplasticity: Visualization creates neural pathways as if experienced
        • Embodied Cognition: Mind-body doesn't distinguish vividly imagined from real
        
        STRUCTURE:
        1. CLARITY: Help them get specific about what they want
        2. EMBODIMENT: Guide sensory-rich visualization (what do you see, feel, hear?)
        3. AFFIRMATION: Create present-tense affirmation for the vision
        4. ACTION: Identify one small aligned action they can take today
        5. RELEASE: Let go of attachment; trust the process
        
        Avoid magical thinking. Connect manifestation to concrete action.
        """
    }
    
    /// Get additional prompting for frequency recommendations
    func getFrequencyModule() -> String {
        return """
        
        FREQUENCY RECOMMENDATIONS:
        Recommend based on user state and goal:
        
        FOCUS/STUDY: Beta waves (13-30 Hz) or Low Beta (13-15 Hz)
        RELAXATION/STRESS: Alpha waves (8-13 Hz)
        MEDITATION/VISUALIZATION: Theta waves (4-8 Hz)
        DEEP SLEEP: Delta waves (0.5-4 Hz)
        HEALING: 528 Hz Solfeggio
        GROUNDING: 432 Hz or 174 Hz
        
        Explain the science briefly: "Alpha waves calm your nervous system while keeping you present."
        Offer duration options: "10 minutes, 20 minutes, or create a custom session?"
        """
    }
}

// MARK: - Notification for Feature Navigation

extension Notification.Name {
    static let navigateToFeature = Notification.Name("navigateToFeature")
}
