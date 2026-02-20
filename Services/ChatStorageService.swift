import Foundation

// MARK: - Chat Session Model (Codable for persistence)

/// Represents a complete chat session with Muse
struct StoredChatSession: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [StoredChatMessage]
    let createdAt: Date
    var updatedAt: Date
    var summary: String? // AI-generated summary of key topics
    var extractedInsights: [String] // Key insights extracted for future context
    
    init(id: UUID = UUID(), title: String = "New Conversation", messages: [StoredChatMessage] = [], createdAt: Date = Date(), summary: String? = nil) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.summary = summary
        self.extractedInsights = []
    }
    
    var lastMessage: String {
        messages.last?.text ?? "No messages"
    }
    
    var messageCount: Int {
        messages.count
    }
    
    /// Generate a title from the first user message
    mutating func generateTitleFromFirstMessage() {
        if let firstUserMessage = messages.first(where: { $0.isUser }) {
            // Take first 50 characters of the first message
            let text = firstUserMessage.text
            title = String(text.prefix(50)) + (text.count > 50 ? "..." : "")
        }
    }
}

/// Represents a single message in a chat session (Codable for persistence)
struct StoredChatMessage: Identifiable, Codable {
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
}

// MARK: - Chat Storage Service

/// Service for persisting and retrieving chat sessions
class ChatStorageService: ObservableObject {
    static let shared = ChatStorageService()
    
    @Published var chatSessions: [StoredChatSession] = []
    @Published var currentSession: StoredChatSession?
    
    private let sessionsKey = "museChatSessions"
    private let currentSessionKey = "museCurrentSessionId"
    private let maxContextSessions = 5 // How many recent sessions to include in AI context
    
    private init() {
        loadChatSessions()
        loadOrCreateCurrentSession()
    }
    
    // MARK: - Session Management
    
    /// Start a new chat session
    func startNewSession() {
        // Save current session first
        if let current = currentSession, !current.messages.isEmpty {
            saveSession(current)
        }
        
        let newSession = StoredChatSession()
        currentSession = newSession
        saveCurrentSessionId(newSession.id)
    }
    
    /// Add a message to the current session
    func addMessage(_ message: StoredChatMessage) {
        guard var session = currentSession else {
            // Create a new session if none exists
            var newSession = StoredChatSession()
            newSession.messages.append(message)
            newSession.updatedAt = Date()
            if message.isUser && newSession.title == "New Conversation" {
                newSession.generateTitleFromFirstMessage()
            }
            currentSession = newSession
            saveSession(newSession)
            return
        }
        
        session.messages.append(message)
        session.updatedAt = Date()
        
        // Generate title from first user message
        if message.isUser && session.title == "New Conversation" {
            session.generateTitleFromFirstMessage()
        }
        
        currentSession = session
        saveSession(session)
    }
    
    /// Save a session to storage
    func saveSession(_ session: StoredChatSession) {
        // Update or add session
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[index] = session
        } else {
            chatSessions.insert(session, at: 0) // Add new sessions at the top
        }
        
        saveChatSessions()
    }
    
    /// Delete a session
    func deleteSession(_ session: StoredChatSession) {
        chatSessions.removeAll(where: { $0.id == session.id })
        
        // If we deleted the current session, start a new one
        if currentSession?.id == session.id {
            startNewSession()
        }
        
        saveChatSessions()
    }
    
    /// Load and switch to a specific session
    func loadSession(_ session: StoredChatSession) {
        // Save current session first
        if let current = currentSession, !current.messages.isEmpty {
            saveSession(current)
        }
        
        currentSession = session
        saveCurrentSessionId(session.id)
    }
    
    // MARK: - Context for AI
    
    /// Get context from past conversations for the AI
    /// Returns a summary of recent conversations to help AI remember context
    func getContextForAI() -> String {
        let recentSessions = chatSessions
            .filter { $0.id != currentSession?.id } // Exclude current session
            .prefix(maxContextSessions)
        
        guard !recentSessions.isEmpty else {
            return ""
        }
        
        var contextParts: [String] = []
        contextParts.append("MEMORY FROM PREVIOUS CONVERSATIONS:")
        
        for (index, session) in recentSessions.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateStr = dateFormatter.string(from: session.updatedAt)
            
            var sessionContext = "[\(index + 1)] Conversation on \(dateStr):"
            
            // Add summary if available
            if let summary = session.summary {
                sessionContext += "\n  Summary: \(summary)"
            }
            
            // Add extracted insights
            if !session.extractedInsights.isEmpty {
                sessionContext += "\n  Key insights: \(session.extractedInsights.joined(separator: "; "))"
            }
            
            // Add last few messages as context (max 4 messages)
            let recentMessages = session.messages.suffix(4)
            if !recentMessages.isEmpty {
                sessionContext += "\n  Recent messages:"
                for msg in recentMessages {
                    let role = msg.isUser ? "User" : "Muse"
                    let truncatedText = String(msg.text.prefix(100)) + (msg.text.count > 100 ? "..." : "")
                    sessionContext += "\n    \(role): \(truncatedText)"
                }
            }
            
            contextParts.append(sessionContext)
        }
        
        return contextParts.joined(separator: "\n\n")
    }
    
    /// Get all topics/themes discussed across sessions
    func getAllTopics() -> [String] {
        var topics: Set<String> = []
        for session in chatSessions {
            topics.formUnion(session.extractedInsights)
        }
        return Array(topics)
    }
    
    // MARK: - Persistence
    
    private func saveChatSessions() {
        do {
            let data = try JSONEncoder().encode(chatSessions)
            UserDefaults.standard.set(data, forKey: sessionsKey)
            debugLog("💬 Saved \(chatSessions.count) chat sessions")
        } catch {
            debugLog("❌ Failed to save chat sessions: \(error)")
        }
    }
    
    private func loadChatSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else {
            chatSessions = []
            return
        }
        
        do {
            chatSessions = try JSONDecoder().decode([StoredChatSession].self, from: data)
            // Sort by most recent first
            chatSessions.sort { $0.updatedAt > $1.updatedAt }
            debugLog("💬 Loaded \(chatSessions.count) chat sessions")
        } catch {
            debugLog("❌ Failed to load chat sessions: \(error)")
            chatSessions = []
        }
    }
    
    private func saveCurrentSessionId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: currentSessionKey)
    }
    
    private func loadOrCreateCurrentSession() {
        // Try to load the last session
        if let idString = UserDefaults.standard.string(forKey: currentSessionKey),
           let id = UUID(uuidString: idString),
           let session = chatSessions.first(where: { $0.id == id }) {
            currentSession = session
        } else if let mostRecent = chatSessions.first {
            // Fall back to most recent session
            currentSession = mostRecent
        } else {
            // No sessions exist, create a new one
            currentSession = StoredChatSession()
        }
    }
    
    // MARK: - Insights Extraction (Future: Call AI to extract)
    
    /// Extract key insights from a session (placeholder - will use AI later)
    func extractInsights(from session: StoredChatSession) -> [String] {
        // This will be enhanced to call the AI to extract key insights
        // For now, create basic insights from keywords
        var insights: [String] = []
        
        let allText = session.messages.map { $0.text }.joined(separator: " ").lowercased()
        
        // Simple keyword-based insight extraction (placeholder)
        let topicKeywords: [(keyword: String, insight: String)] = [
            ("anxious", "Discussed feelings of anxiety"),
            ("anxiety", "Discussed feelings of anxiety"),
            ("stress", "Talked about stress"),
            ("work", "Mentioned work-related topics"),
            ("relationship", "Discussed relationships"),
            ("family", "Mentioned family"),
            ("sleep", "Talked about sleep"),
            ("happy", "Expressed happiness"),
            ("sad", "Expressed sadness"),
            ("grateful", "Practiced gratitude"),
            ("goal", "Discussed goals"),
            ("meditation", "Mentioned meditation"),
            ("exercise", "Talked about exercise"),
            ("health", "Discussed health topics")
        ]
        
        for (keyword, insight) in topicKeywords {
            if allText.contains(keyword) && !insights.contains(insight) {
                insights.append(insight)
            }
        }
        
        return insights
    }
}
