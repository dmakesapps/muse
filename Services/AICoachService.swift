import Foundation

struct AICoachService {
    private static let apiEndpoint = "https://api.anthropic.com/v1/messages"
    
    // MARK: - Main AI Interaction
    static func sendMessage(
        _ userMessage: String,
        conversationHistory: [Message],
        userProfile: UserProfile,
        currentPromises: [Promise]
    ) async throws -> String {
        
        let systemPrompt = buildSystemPrompt(
            profile: userProfile,
            promises: currentPromises
        )
        
        let messages = buildMessageHistory(
            history: conversationHistory,
            newMessage: userMessage
        )
        
        let response = try await callClaudeAPI(
            systemPrompt: systemPrompt,
            messages: messages
        )
        
        return response
    }
    
    // MARK: - Generate Personalized Notification
    static func generateNotificationMessage(
        for promise: Promise,
        userProfile: UserProfile
    ) async throws -> String {
        
        let prompt = """
        Generate a motivating, personalized notification message for this promise:
        
        Promise: "\(promise.text)"
        User's context: \(promise.userContext ?? "No context provided")
        
        Requirements:
        - Keep it under 100 characters
        - Be encouraging and personal
        - Reference their goal or context if available
        - Use a warm, supportive tone
        - Don't use generic phrases
        - DO NOT mention scores, percentages, progress, or statistics
        - DO NOT reference how many times the promise has been kept
        - DO NOT use em dashes (—) or other special punctuation - use regular hyphens (-) or commas instead
        - Write naturally and authentically, as if speaking directly to the user
        - MUST use complete sentences with proper grammar and punctuation
        - Avoid fragments, incomplete thoughts, or sentence fragments
        
        Return ONLY the notification message text, nothing else.
        """
        
        let messages = [[
            "role": "user",
            "content": prompt
        ]]
        
        let response = try await callClaudeAPI(
            systemPrompt: "You are a supportive accountability coach. Always write in complete sentences with proper grammar and punctuation. Avoid fragments or incomplete thoughts.",
            messages: messages
        )
        
        // Remove em dashes and replace with regular hyphens or commas
        let cleanedResponse = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "–", with: "-") // en dash
        
        return cleanedResponse
    }
    
    // MARK: - Generate Notification with Agent
    static func generateNotificationWithAgent(
        for promise: Promise,
        agent: NotificationAgent,
        userProfile: UserProfile
    ) async throws -> String {
        // Validate agent has a system prompt
        guard !agent.systemPrompt.isEmpty else {
            throw NSError(domain: "AICoachService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Agent system prompt is empty"])
        }
        
        // Build a prompt that emphasizes character consistency and uses the agent's examples
        let prompt = """
        Generate a notification message for this promise. You are \(agent.name), and you must speak EXACTLY in your character's voice as defined in your system prompt.
        
        THE PROMISE: "\(promise.text)"
        USER'S CONTEXT: \(promise.userContext ?? "No specific context provided")
        CURRENT TIME: \(Date().formatted(date: .omitted, time: .shortened))
        
        CRITICAL: 
        - Look at the EXAMPLE NOTIFICATIONS in your system prompt - that's how you speak
        - Generate a message in that EXACT same voice and style
        - This message must be UNIQUE and DIFFERENT from any previous notification
        - It must relate to the specific promise: "\(promise.text)"
        - Keep it under 100 characters
        - Speak as \(agent.name), not as a generic coach
        - DO NOT use generic phrases like "You've got this!" or "Keep going!"
        - DO NOT mention scores, percentages, progress, statistics, or how many times the promise has been kept
        - DO NOT use em dashes (—) or other special punctuation - use regular hyphens (-) or commas instead
        - Write naturally and authentically, as if speaking directly to the user
        - MUST use complete sentences with proper grammar and punctuation
        - Avoid fragments, incomplete thoughts, or sentence fragments
        - Your personality is: \(agent.personalityDescription)
        
        Your system prompt contains example notifications showing your exact voice. Generate a NEW message in that same voice, but make it unique and specific to this promise.
        
        Return ONLY the notification message text. No explanations, no quotes, no prefixes. Just the raw message in your character's voice.
        """
        
        let messages = [[
            "role": "user",
            "content": prompt
        ]]
        
        do {
            let response = try await callClaudeAPI(
                systemPrompt: agent.systemPrompt,
                messages: messages
            )
            
            // Remove em dashes, en dashes, and quotes, replace with regular hyphens or commas
            let trimmedResponse = response
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "") // Remove quotes if present
                .replacingOccurrences(of: "—", with: "-") // em dash
                .replacingOccurrences(of: "–", with: "-") // en dash
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return trimmedResponse
        } catch {
            throw error
        }
    }
    
    // MARK: - Clarify Agent Details
    // First step: Ask clarifying questions to understand the agent better
    static func clarifyAgentDetails(
        name: String,
        personalityDescription: String,
        userProfile: UserProfile
    ) async throws -> String {
        let clarificationPrompt = """
        The user wants to create a notification agent with:
        - Name: \(name)
        - Initial description: \(personalityDescription)
        
        Your task is to ask thoughtful clarifying questions to ensure you fully understand what kind of agent they want, especially if they mention:
        - Specific people (e.g., "David Goggins", "Oprah", "Tony Robbins")
        - Character types (e.g., "military drill sergeant", "gentle therapist", "motivational speaker")
        - Fictional characters (e.g., "Yoda", "Gandalf")
        - Public figures or celebrities
        
        IMPORTANT GUIDELINES:
        - If they mention a specific person, ask about which aspects of that person they want (speaking style, tone, specific phrases, energy level, etc.)
        - Ask about the communication style they prefer (short/direct, longer/encouraging, tough love, gentle, etc.)
        - Ask about tone (serious, playful, intense, calm, etc.)
        - Ask about any specific phrases, words, or communication patterns they want
        - Ask about the energy level (high energy, calm, intense, etc.)
        - If they mention someone you're not familiar with, ask them to describe that person's communication style
        
        Keep your questions conversational and helpful. Ask 2-4 thoughtful questions that will help you create an accurate agent.
        Do NOT create the agent yet - just ask clarifying questions.
        """
        
        let messages = [[
            "role": "user",
            "content": clarificationPrompt
        ]]
        
        let systemPrompt = buildSystemPrompt(
            profile: userProfile,
            promises: []
        )
        
        let response = try await callClaudeAPI(
            systemPrompt: systemPrompt,
            messages: messages
        )
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Create Notification Agent
    // This will use a master prompt (to be provided) to create an agent from user description
    static func createNotificationAgent(
        name: String,
        personalityDescription: String,
        clarificationAnswers: String?,
        masterPrompt: String
    ) async throws -> (systemPrompt: String, suggestedName: String?) {
        // Build the full description including clarification answers
        var fullDescription = personalityDescription
        if let answers = clarificationAnswers, !answers.isEmpty {
            fullDescription += "\n\nAdditional details from clarification: \(answers)"
        }
        
        let prompt = """
        \(masterPrompt)
        
        User wants to create a notification agent with:
        - Name: \(name)
        - Personality description: \(fullDescription)
        
        CRITICAL: If the user mentioned a specific person, character, or type of person, ensure you accurately represent:
        - Their authentic speaking style and voice
        - Their characteristic phrases and word choices
        - Their tone and energy level
        - Their communication patterns
        - Their personality traits that come through in how they speak
        
        If you're not certain about a specific person mentioned, use the user's description and clarification answers to create an accurate representation. Do not make assumptions about people you're not familiar with - use only what the user has described.
        
        Please create a system prompt for this agent and suggest a name if the provided name could be improved.
        Output in format: AGENT_CREATE|systemPrompt|suggestedName
        """
        
        let messages = [[
            "role": "user",
            "content": prompt
        ]]
        
        let response = try await callClaudeAPI(
            systemPrompt: "You are an expert at creating AI agent personalities for notification systems. You ensure accuracy when representing specific people or character types. When creating example notifications, DO NOT use em dashes (—) or en dashes (–) - use regular hyphens (-) or commas instead for a more authentic, natural feel.",
            messages: messages
        )
        
        // Parse the response
        return parseAgentCreationResponse(response, userProvidedName: name)
    }
    
    private static func parseAgentCreationResponse(_ response: String, userProvidedName: String) -> (systemPrompt: String, suggestedName: String?) {
        // Look for AGENT_CREATE|systemPrompt|suggestedName format
        guard response.contains("AGENT_CREATE") else {
            // Fallback: use response as system prompt
            return (systemPrompt: response.trimmingCharacters(in: .whitespacesAndNewlines), suggestedName: nil)
        }
        
        let lines = response.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("AGENT_CREATE") {
                let components = line.components(separatedBy: "|")
                if components.count >= 2 {
                    let systemPrompt = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let suggestedName = components.count > 2 ? components[2].trimmingCharacters(in: .whitespacesAndNewlines) : nil
                    return (systemPrompt: systemPrompt, suggestedName: suggestedName)
                }
            }
        }
        
        // Fallback
        return (systemPrompt: response.trimmingCharacters(in: .whitespacesAndNewlines), suggestedName: nil)
    }
    
    // MARK: - Parse Promise from Conversation
    static func parsePromiseFromConversation(
        _ aiResponse: String
    ) -> PromiseIntent? {
        // Look for structured data in AI response
        // Expected format: "PROMISE_CREATE|Promise text|YYYY-MM-DD HH:mm|Context"
        
        // Check if response contains PROMISE_CREATE anywhere
        guard aiResponse.contains("PROMISE_CREATE") else {
            return nil
        }
        
        // Find the FIRST PROMISE_CREATE line - it might be on its own line or embedded
        let lines = aiResponse.components(separatedBy: .newlines)
        var promiseLine: String?
        
        for line in lines {
            if line.contains("PROMISE_CREATE") {
                promiseLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                break // Only take the first occurrence
            }
        }
        
        // If not found on separate line, try the whole response but only up to the first PROMISE_CREATE
        let textToParse: String
        if let promiseLine = promiseLine {
            textToParse = promiseLine
        } else {
            // Extract only up to the first PROMISE_CREATE to avoid parsing duplicates
            if let firstRange = aiResponse.range(of: "PROMISE_CREATE") {
                // Find the end of the first PROMISE_CREATE command (up to newline or end of string)
                let afterMarker = String(aiResponse[firstRange.lowerBound...])
                if let newlineRange = afterMarker.range(of: "\n") {
                    textToParse = String(afterMarker[..<newlineRange.lowerBound])
                } else {
                    textToParse = afterMarker
                }
            } else {
                textToParse = aiResponse
            }
        }
        
        // Extract just the PROMISE_CREATE part if it's embedded in text
        let components = textToParse.components(separatedBy: "|")
        
        // Find where PROMISE_CREATE starts
        var startIndex = 0
        for (index, component) in components.enumerated() {
            if component.contains("PROMISE_CREATE") {
                startIndex = index
                break
            }
        }
        
        // If PROMISE_CREATE is in the middle of text, extract it
        let promiseCreatePart = components[startIndex]
        if promiseCreatePart.contains("PROMISE_CREATE") && !promiseCreatePart.hasPrefix("PROMISE_CREATE") {
            // Extract from the PROMISE_CREATE marker onwards
            if let range = promiseCreatePart.range(of: "PROMISE_CREATE") {
                let afterMarker = String(promiseCreatePart[range.upperBound...])
                let remainingComponents = afterMarker.components(separatedBy: "|")
                let allComponents = ["PROMISE_CREATE"] + remainingComponents + Array(components[(startIndex + 1)...])
                
                guard allComponents.count >= 3 else {
                    return nil
                }
                
                return parseComponents(allComponents)
            }
        }
        
        guard components.count >= 3,
              components[startIndex].contains("PROMISE_CREATE") else {
            return nil
        }
        
        // Use components starting from PROMISE_CREATE
        let relevantComponents = Array(components[startIndex...])
        guard relevantComponents.count >= 3 else {
            return nil
        }
        
        return parseComponents(relevantComponents)
    }
    
    private static func parseComponents(_ components: [String]) -> PromiseIntent? {
        guard components.count >= 3 else { return nil }
        
        let text = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let dateString = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let context = components.count > 3 ? components[3].trimmingCharacters(in: .whitespacesAndNewlines) : nil
        
        // Try multiple date formats
        var date: Date?
        
        // Clean the date string (remove any extra whitespace)
        let cleanDateString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try ISO8601 format first (with timezone)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatter.timeZone = TimeZone.current
        date = isoFormatter.date(from: cleanDateString)
        
        // Try ISO8601 without fractional seconds
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: cleanDateString)
        }
        
        // Try standard date format with T separator
        if date == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "en_US_POSIX")
            date = formatter.date(from: cleanDateString)
        }
        
        // Try with space separator
        if date == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "en_US_POSIX")
            date = formatter.date(from: cleanDateString)
        }
        
        // Try just date without time (default to 9am)
        if date == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let dateOnly = formatter.date(from: cleanDateString) {
                // Set to 9am on that date
                var components = Calendar.current.dateComponents([.year, .month, .day], from: dateOnly)
                components.hour = 9
                components.minute = 0
                date = Calendar.current.date(from: components)
            }
        }
        
        // If still no date, use current time + 1 day as fallback
        guard let date = date else {
            print("⚠️ Could not parse date '\(dateString)', using fallback (tomorrow)")
            // Fallback: schedule for tomorrow at the same time
            return PromiseIntent(
                text: text,
                due: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                context: context
            )
        }
        
        print("✅ Successfully parsed date: \(date)")
        return PromiseIntent(text: text, due: date, context: context)
    }
    
    // MARK: - Helper Functions
    private static func buildSystemPrompt(
        profile: UserProfile,
        promises: [Promise]
    ) -> String {
        """
        You are an AI accountability coach for Pacto, an app that helps people create and keep their promises. Your mission is to be a supportive, understanding, and motivating partner in the user's journey toward personal growth and commitment.
        
        CORE PRINCIPLES:
        - You are a coach, not a judge. Support users without judgment or shame.
        - Focus on progress, not perfection. Celebrate small wins and learn from setbacks.
        - Be empathetic and understanding. Everyone struggles with commitments at times.
        - Keep conversations natural and human-like. Avoid technical jargon or code-like responses.
        - Stay within your role as an accountability coach. Do not provide medical, legal, or financial advice.
        - Respect user privacy and boundaries. Never ask for sensitive personal information.
        
        RESPONSE GUIDELINES:
        - NEVER include code, commands, technical syntax, or programming language in your responses
        - NEVER show markdown formatting, backticks, or technical notation to users
        - Speak naturally and conversationally, as if you're a trusted friend and coach
        - Keep responses concise (under 150 words) and focused on the user's needs
        - Use warm, supportive language that encourages without being pushy
        - Be specific and actionable in your suggestions
        
        User Profile:
        - Name: \(profile.name ?? "User")
        - Total promises: \(profile.totalPromises)
        - Context: \(profile.conversationContext)
        
        Current Active Promises:
        \(formatPromisesForAI(promises))
        
        YOUR ROLE:
        1. Help users create meaningful promises through natural conversation
        2. Ask thoughtful, clarifying questions about timing, motivation, and context
        3. Provide personalized encouragement and accountability support
        4. Celebrate successes authentically and help users learn from challenges
        5. Suggest realistic promise adjustments based on patterns and user needs
        
        CREATING PROMISES:
        - Ask about their motivation and why this promise matters to them
        - Help them set realistic, achievable goals
        - Confirm specific times and schedules that work for their life
        - Use the CURRENT DATE: \(Date().formatted(date: .complete, time: .omitted))
        - For relative dates like "next week", calculate the actual date
        - Once confirmed, output ONLY this format on a separate line: PROMISE_CREATE|promise text|ISO8601 datetime|context
        - IMPORTANT: The datetime must be in ISO8601 format: YYYY-MM-DDTHH:mm:ss (e.g., 2024-11-20T07:00:00)
        - Always use dates in the future relative to today
        - Do NOT explain the format or show it to the user - just output it when ready
        
        DISCUSSING EXISTING PROMISES:
        - Provide personalized encouragement based on their journey
        - Suggest practical strategies for improvement
        - Acknowledge their current notification schedule and duration settings
        - When user asks to edit a promise, reference the current settings naturally
        - DO NOT mention scores, percentages, progress, statistics, or how many times promises have been kept
        
        EDITING PROMISES:
        - Acknowledge the current settings in a conversational way
        - Confirm what changes they want to make
        - Note that frequency and duration changes will be applied when they save in the edit screen
        - Be supportive if they're adjusting because something wasn't working
        
        REMEMBER: You are here to support, not to judge. Every conversation should feel like talking to a caring coach who believes in the user's ability to succeed.
        """
    }
    
    private static func formatPromisesForAI(_ promises: [Promise]) -> String {
        promises.map { promise in
            var details = "- \"\(promise.text)\""
            
            // Add frequency information
            if !promise.customDailyTimes.isEmpty {
                let times = promise.customDailyTimes.map { time in
                    let (hour, minute) = DateUtils.timeComponents(from: time)
                    return String(format: "%d:%02d %@", hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour), minute, hour >= 12 ? "PM" : "AM")
                }
                details += "\n  Frequency: Daily at \(times.joined(separator: ", "))"
            } else if !promise.customWeeklyDays.isEmpty && !promise.customWeeklyTimes.isEmpty {
                let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                let days = promise.customWeeklyDays.sorted().map { weekdays[$0 - 1] }.joined(separator: ", ")
                let times = promise.customWeeklyTimes.map { time in
                    let (hour, minute) = DateUtils.timeComponents(from: time)
                    return String(format: "%d:%02d %@", hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour), minute, hour >= 12 ? "PM" : "AM")
                }
                details += "\n  Frequency: Weekly on \(days) at \(times.joined(separator: ", "))"
            } else if let monthlyDay = promise.customMonthlyDay, !promise.customMonthlyTimes.isEmpty {
                let times = promise.customMonthlyTimes.map { time in
                    let (hour, minute) = DateUtils.timeComponents(from: time)
                    return String(format: "%d:%02d %@", hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour), minute, hour >= 12 ? "PM" : "AM")
                }
                details += "\n  Frequency: Monthly on day \(String(monthlyDay)) at \(times.joined(separator: ", "))"
            } else {
                details += "\n  Frequency: Not configured"
            }
            
            // Add duration information
            if let durationDays = promise.durationDays {
                let days = durationDays
                let weeks = days / 7
                let months = days / 30
                let years = days / 365
                
                var durationString = ""
                if years > 0 {
                    durationString = "\(years) year\(years > 1 ? "s" : "")"
                } else if months > 0 {
                    durationString = "\(months) month\(months > 1 ? "s" : "")"
                } else if weeks > 0 {
                    durationString = "\(weeks) week\(weeks > 1 ? "s" : "")"
                } else {
                    durationString = "\(days) day\(days > 1 ? "s" : "")"
                }
                
                if let endDate = promise.endDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    details += "\n  Duration: \(durationString) (ends: \(formatter.string(from: endDate)))"
                } else {
                    details += "\n  Duration: \(durationString)"
                }
            } else {
                details += "\n  Duration: No end date (continues indefinitely)"
            }
            
            return details
        }.joined(separator: "\n\n")
    }
    
    private static func buildMessageHistory(
        history: [Message],
        newMessage: String
    ) -> [[String: String]] {
        var messages: [[String: String]] = []
        
        // Add conversation history
        for msg in history.suffix(10) { // Keep last 10 messages for context
            messages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        // Add new message
        messages.append([
            "role": "user",
            "content": newMessage
        ])
        
        return messages
    }
    
    private static func callClaudeAPI(
        systemPrompt: String,
        messages: [[String: String]]
    ) async throws -> String {
        
        guard let url = URL(string: apiEndpoint) else {
            throw AICoachError.apiError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Get API key from secure location
        guard let apiKey = Config.anthropicAPIKey else {
            throw AICoachError.apiError
        }
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "system": systemPrompt,
            "messages": messages
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🌐 Calling Claude API...")
        print("📡 Endpoint: \(apiEndpoint)")
        print("🔑 API Key present: \(!apiKey.isEmpty)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw AICoachError.apiError
        }
        
        print("📊 HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let errorMessage = error["message"] as? String {
                print("❌ API Error: \(errorMessage)")
            } else if let errorString = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorString)")
            }
            
            switch httpResponse.statusCode {
            case 401:
                print("❌ Authentication failed - check API key")
                throw AICoachError.apiError
            case 429:
                print("❌ Rate limit exceeded")
                throw AICoachError.apiError
            case 500...599:
                print("❌ Server error")
                throw AICoachError.apiError
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                throw AICoachError.apiError
            }
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            print("❌ Failed to parse response")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Response data: \(jsonString)")
            }
            throw AICoachError.parsingError
        }
        
        print("✅ API call successful")
        return text
    }
    
    // MARK: - Promise Edit Message
    // MARK: - Notification Content Editing
    static func sendNotificationContentMessage(
        _ userMessage: String,
        conversationHistory: [Message],
        userProfile: UserProfile,
        promise: Promise
    ) async throws -> String {
        
        let systemPrompt = buildNotificationContentSystemPrompt(
            profile: userProfile,
            promise: promise
        )
        
        let messages = buildMessageHistory(
            history: conversationHistory,
            newMessage: userMessage
        )
        
        let response = try await callClaudeAPI(
            systemPrompt: systemPrompt,
            messages: messages
        )
        
        return response
    }
    
    private static func buildNotificationContentSystemPrompt(
        profile: UserProfile,
        promise: Promise
    ) -> String {
        let currentMessage = promise.notificationMessage ?? "No custom message set"
        
        return """
        You are an AI assistant helping a user customize the notification message content for their promise.
        
        User Profile:
        - Name: \(profile.name ?? "User")
        
        Current Promise:
        - Promise: "\(promise.text)"
        - Current notification message: "\(currentMessage)"
        
        Your role:
        1. Help the user describe what kind of notification message they want
        2. Understand their preferences (motivational, factual, encouraging, etc.)
        3. Generate a personalized notification message based on their request
        4. Be warm, supportive, and concise
        
        IMPORTANT: When you generate a new notification message, you MUST output it in this exact format on a separate line:
        NOTIFICATION_CONTENT|message text here
        
        The message should:
        - Be under 100 characters
        - Be encouraging and personal
        - Reference their goal if appropriate
        - Match the tone/style they requested
        - DO NOT use em dashes (—) or en dashes (–) - use regular hyphens (-) or commas instead for a more authentic, natural feel
        - MUST use complete sentences with proper grammar and punctuation
        - Avoid fragments, incomplete thoughts, or sentence fragments
        
        Examples:
        - User says "make it more motivational": NOTIFICATION_CONTENT|You've got this! Time to work on your goal: \(promise.text)
        - User says "make it shorter and direct": NOTIFICATION_CONTENT|Time for: \(promise.text)
        - User says "remind me why this matters": NOTIFICATION_CONTENT|Remember your commitment: \(promise.text) - you're building a better you!
        
        Always output NOTIFICATION_CONTENT on its own line when generating a message. Be warm, supportive, and concise. Keep responses under 150 words.
        """
    }
    
    static func parseNotificationContentFromConversation(_ aiResponse: String) -> String? {
        guard aiResponse.contains("NOTIFICATION_CONTENT") else {
            return nil
        }
        
        let lines = aiResponse.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("NOTIFICATION_CONTENT") {
                let components = line.components(separatedBy: "|")
                if components.count > 1 {
                    let message = components[1...].joined(separator: "|")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "—", with: "-") // em dash
                        .replacingOccurrences(of: "–", with: "-") // en dash
                    return message.isEmpty ? nil : message
                }
            }
        }
        
        return nil
    }
    
    private static func buildPromiseEditSystemPrompt(
        profile: UserProfile,
        promise: Promise
    ) -> String {
        let frequencyInfo = formatPromiseForAI(promise)
        
        return """
        You are an AI accountability coach helping a user edit their promise.
        
        User Profile:
        - Name: \(profile.name ?? "User")
        
        Current Promise Details:
        \(frequencyInfo)
        
        Your role:
        1. Help the user modify their promise through natural conversation
        2. Understand what they want to change (frequency, duration, goal text, notification style)
        3. Confirm the changes before applying them
        4. Be supportive and encouraging
        
        When the user wants to edit the promise:
        - For frequency changes: Ask about the new schedule (daily times, weekly days/times, monthly day/times)
        - For duration changes: Ask how long they want the promise to last
        - For goal text changes: Confirm the new promise text
        - For notification style: Ask what kind of messages they want (motivational, factual, etc.)
        
        IMPORTANT: When the user confirms changes, you MUST output the changes in this exact format on a separate line:
        PROMISE_EDIT|field1:value1|field2:value2|...
        
        Available fields:
        - text: New promise text (use this if they want to change the goal)
        - dailyTimes: Comma-separated times in HH:mm format (e.g., "09:00,14:00,19:00" for 9am, 2pm, 7pm)
        - weeklyDays: Comma-separated weekday numbers 1-7 (1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday)
        - weeklyTimes: Comma-separated times in HH:mm format
        - monthlyDay: Day of month 1-31
        - monthlyTimes: Comma-separated times in HH:mm format
        - durationDays: Number of days (e.g., "30" for 30 days, "90" for 3 months)
        - removeDuration: "true" to remove duration
        - notificationStyle: Description of desired notification tone/style
        
        Examples:
        - User says "change to 3 times a day at 9am, 2pm, and 7pm": PROMISE_EDIT|dailyTimes:09:00,14:00,19:00
        - User says "set duration to 30 days": PROMISE_EDIT|durationDays:30
        - User says "change the goal to read 20 pages": PROMISE_EDIT|text:I will read 20 pages every day
        - User says "make it weekly on Monday and Wednesday at 7pm": PROMISE_EDIT|weeklyDays:2,4|weeklyTimes:19:00
        
        Always output PROMISE_EDIT on its own line when making changes. Be warm, supportive, and concise. Keep responses under 150 words.
        """
    }
    
    private static func formatPromiseForAI(_ promise: Promise) -> String {
        var details = "Promise: \"\(promise.text)\"\n"
        
        if !promise.customDailyTimes.isEmpty {
            let times = promise.customDailyTimes.map { time in
                let (hour, minute) = DateUtils.timeComponents(from: time)
                return String(format: "%02d:%02d", hour, minute)
            }
            details += "Frequency: Daily at \(times.joined(separator: ", "))\n"
        } else if !promise.customWeeklyDays.isEmpty && !promise.customWeeklyTimes.isEmpty {
            let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let days = promise.customWeeklyDays.sorted().map { weekdays[$0 - 1] }.joined(separator: ", ")
            let times = promise.customWeeklyTimes.map { time in
                let (hour, minute) = DateUtils.timeComponents(from: time)
                return String(format: "%02d:%02d", hour, minute)
            }
            details += "Frequency: Weekly on \(days) at \(times.joined(separator: ", "))\n"
        } else if let monthlyDay = promise.customMonthlyDay, !promise.customMonthlyTimes.isEmpty {
            let times = promise.customMonthlyTimes.map { time in
                let (hour, minute) = DateUtils.timeComponents(from: time)
                return String(format: "%02d:%02d", hour, minute)
            }
            details += "Frequency: Monthly on day \(String(monthlyDay)) at \(times.joined(separator: ", "))\n"
        }
        
        if let durationDays = promise.durationDays {
            details += "Duration: \(durationDays) days"
            if let endDate = promise.endDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                details += " (ends: \(formatter.string(from: endDate)))"
            }
        } else {
            details += "Duration: No end date"
        }
        
        return details
    }
    
    static func parsePromiseEditFromConversation(
        _ aiResponse: String,
        promise: Promise
    ) -> PromiseEditIntent? {
        print("🔍 parsePromiseEditFromConversation called")
        print("📝 Full AI response: \(aiResponse)")
        
        guard aiResponse.contains("PROMISE_EDIT") else {
            print("❌ No PROMISE_EDIT found in response")
            return nil
        }
        
        let lines = aiResponse.components(separatedBy: .newlines)
        var promiseLine: String?
        
        for line in lines {
            if line.contains("PROMISE_EDIT") {
                promiseLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Found PROMISE_EDIT line: '\(promiseLine)'")
                break
            }
        }
        
        let textToParse = promiseLine ?? aiResponse
        let components = textToParse.components(separatedBy: "|")
        
        print("📦 Split into \(components.count) components: \(components)")
        
        guard let editIndex = components.firstIndex(where: { $0.contains("PROMISE_EDIT") }) else {
            print("❌ Could not find PROMISE_EDIT in components")
            return nil
        }
        
        print("✅ Found PROMISE_EDIT at index \(editIndex)")
        
        var editIntent = PromiseEditIntent()
        
        // Parse fields after PROMISE_EDIT
        for component in components[(editIndex + 1)...] {
            let trimmedComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedComponent.isEmpty else { continue }
            
            let parts = trimmedComponent.components(separatedBy: ":")
            guard parts.count == 2 else {
                print("⚠️ Skipping component with invalid format: '\(trimmedComponent)' (parts: \(parts.count))")
                continue
            }
            
            let field = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("🔧 Parsing field: '\(field)' = '\(value)'")
            
            switch field {
            case "text":
                editIntent.text = value
                print("📝 Parsed text field: '\(value)'")
            case "dailyTimes":
                editIntent.dailyTimes = parseTimeStrings(value)
                print("⏰ Parsed dailyTimes: \(editIntent.dailyTimes?.count ?? 0) times")
            case "weeklyDays":
                editIntent.weeklyDays = parseWeekdayStrings(value)
                print("📅 Parsed weeklyDays: \(editIntent.weeklyDays?.count ?? 0) days")
            case "weeklyTimes":
                editIntent.weeklyTimes = parseTimeStrings(value)
                print("⏰ Parsed weeklyTimes: \(editIntent.weeklyTimes?.count ?? 0) times")
            case "monthlyDay":
                editIntent.monthlyDay = Int(value)
                print("📆 Parsed monthlyDay: \(editIntent.monthlyDay ?? -1)")
            case "monthlyTimes":
                editIntent.monthlyTimes = parseTimeStrings(value)
                print("⏰ Parsed monthlyTimes: \(editIntent.monthlyTimes?.count ?? 0) times")
            case "durationDays":
                editIntent.durationDays = Int(value)
                print("⏳ Parsed durationDays: \(editIntent.durationDays ?? -1)")
            case "removeDuration":
                editIntent.removeDuration = value.lowercased() == "true"
                print("⏳ Parsed removeDuration: \(editIntent.removeDuration ?? false)")
            case "notificationStyle":
                editIntent.notificationStyle = value
                print("💬 Parsed notificationStyle: '\(value)'")
            default:
                print("⚠️ Unknown field: '\(field)' with value: '\(value)'")
                break
            }
        }
        
        // Return nil if no changes were specified
        if editIntent.text == nil && editIntent.dailyTimes == nil && 
           editIntent.weeklyDays == nil && editIntent.weeklyTimes == nil &&
           editIntent.monthlyDay == nil && editIntent.monthlyTimes == nil &&
           editIntent.durationDays == nil && editIntent.removeDuration == nil &&
           editIntent.notificationStyle == nil {
            print("❌ No valid changes found in edit intent")
            return nil
        }
        
        print("✅ Edit intent created successfully with changes")
        return editIntent
    }
    
    private static func parseTimeStrings(_ timeString: String) -> [Date]? {
        let timeStrings = timeString.components(separatedBy: ",")
        let calendar = Calendar.current
        var dates: [Date] = []
        
        print("🕐 Parsing time string: '\(timeString)'")
        
        for timeStr in timeStrings {
            let trimmed = timeStr.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.components(separatedBy: ":")
            
            print("🕐 Parsing individual time: '\(trimmed)', parts: \(parts)")
            
            if parts.count == 2,
               let hour = Int(parts[0]),
               let minute = Int(parts[1]),
               hour >= 0 && hour < 24,
               minute >= 0 && minute < 60 {
                if let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                    dates.append(date)
                    print("✅ Parsed time: \(hour):\(minute) -> \(date)")
                } else {
                    print("❌ Failed to create date from hour: \(hour), minute: \(minute)")
                }
            } else {
                print("❌ Invalid time format: '\(trimmed)' (parts: \(parts.count), hour: \(parts.count > 0 ? parts[0] : "nil"), minute: \(parts.count > 1 ? parts[1] : "nil"))")
            }
        }
        
        print("🕐 Final parsed dates: \(dates.count) dates")
        return dates.isEmpty ? nil : dates
    }
    
    private static func parseWeekdayStrings(_ dayString: String) -> [Int]? {
        let dayStrings = dayString.components(separatedBy: ",")
        var weekdays: [Int] = []
        
        for dayStr in dayStrings {
            if let day = Int(dayStr.trimmingCharacters(in: .whitespacesAndNewlines)),
               day >= 1 && day <= 7 {
                weekdays.append(day)
            }
        }
        
        return weekdays.isEmpty ? nil : weekdays
    }
}

// MARK: - Supporting Types
struct PromiseIntent {
    let text: String
    let due: Date
    let context: String?
}

struct PromiseEditIntent {
    var text: String?
    var dailyTimes: [Date]?
    var weeklyDays: [Int]?
    var weeklyTimes: [Date]?
    var monthlyDay: Int?
    var monthlyTimes: [Date]?
    var durationDays: Int?
    var removeDuration: Bool?
    var notificationStyle: String?
}

enum AICoachError: Error {
    case apiError
    case parsingError
    case invalidResponse
}

