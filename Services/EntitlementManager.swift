import SwiftUI

// MARK: - Usage Limit Source (for UI messaging)
enum UsageLimitSource: String {
    case chatMessages = "chat_messages"
    case aiGeneration = "ai_generation"
    case journalInsights = "journal_insights"
}

// MARK: - EntitlementManager (Free Tier with Daily Rate Limits)
/// Manages daily usage limits for AI-powered features.
/// No paywall, no Superwall — just sustainable rate limiting.
@MainActor
class EntitlementManager: NSObject, ObservableObject {
    static let shared = EntitlementManager()
    
    // MARK: - Daily Limits
    private let maxDailyChatMessages = 25
    private let maxDailyAIGenerations = 5
    private let maxDailyJournalInsights = 3
    
    // MARK: - Published State
    @Published var showUsageLimitAlert: Bool = false
    @Published var usageLimitSource: UsageLimitSource? = nil
    
    // MARK: - UserDefaults Keys
    private let chatCountKey = "dailyChatMessageCount"
    private let aiGenCountKey = "dailyAIGenerationCount"
    private let journalCountKey = "dailyJournalInsightCount"
    private let lastResetDateKey = "dailyUsageResetDate"
    
    private override init() {
        super.init()
        resetDailyCountsIfNeeded()
        debugLog("✅ EntitlementManager: Initialized (Free tier with daily rate limits)")
        debugLog("   Chat: \(currentChatCount)/\(maxDailyChatMessages)")
        debugLog("   AI Gen: \(currentAIGenCount)/\(maxDailyAIGenerations)")
        debugLog("   Journal: \(currentJournalCount)/\(maxDailyJournalInsights)")
    }
    
    // MARK: - Current Counts
    private var currentChatCount: Int {
        UserDefaults.standard.integer(forKey: chatCountKey)
    }
    
    private var currentAIGenCount: Int {
        UserDefaults.standard.integer(forKey: aiGenCountKey)
    }
    
    private var currentJournalCount: Int {
        UserDefaults.standard.integer(forKey: journalCountKey)
    }
    
    // MARK: - Remaining Counts (for UI)
    var remainingChatMessages: Int {
        max(0, maxDailyChatMessages - currentChatCount)
    }
    
    var remainingAIGenerations: Int {
        max(0, maxDailyAIGenerations - currentAIGenCount)
    }
    
    var remainingJournalInsights: Int {
        max(0, maxDailyJournalInsights - currentJournalCount)
    }
    
    // MARK: - Can Use Checks
    
    /// Check if user can send a chat message. Always returns true (we increment after).
    /// We allow the message to go through and just inform them when they're near/at the limit.
    func canSendChatMessage() -> Bool {
        resetDailyCountsIfNeeded()
        if currentChatCount >= maxDailyChatMessages {
            showLimitReached(source: .chatMessages)
            return false
        }
        return true
    }
    
    /// Check if user can use AI features (affirmation generation).
    func canUseAIFeatures() -> Bool {
        resetDailyCountsIfNeeded()
        if currentAIGenCount >= maxDailyAIGenerations {
            showLimitReached(source: .aiGeneration)
            return false
        }
        return true
    }
    
    /// Check if user can generate journal insights.
    func canUseJournalInsights() -> Bool {
        resetDailyCountsIfNeeded()
        if currentJournalCount >= maxDailyJournalInsights {
            showLimitReached(source: .journalInsights)
            return false
        }
        return true
    }
    
    /// Sessions are always allowed (no cost to us).
    func canPlaySession() -> Bool {
        return true
    }
    
    // MARK: - Increment Usage
    
    func incrementChatMessageCount() {
        resetDailyCountsIfNeeded()
        let newCount = currentChatCount + 1
        UserDefaults.standard.set(newCount, forKey: chatCountKey)
        debugLog("💬 EntitlementManager: Chat message \(newCount)/\(maxDailyChatMessages)")
    }
    
    func incrementAIGenerationCount() {
        resetDailyCountsIfNeeded()
        let newCount = currentAIGenCount + 1
        UserDefaults.standard.set(newCount, forKey: aiGenCountKey)
        debugLog("🌟 EntitlementManager: AI generation \(newCount)/\(maxDailyAIGenerations)")
    }
    
    func incrementJournalInsightCount() {
        resetDailyCountsIfNeeded()
        let newCount = currentJournalCount + 1
        UserDefaults.standard.set(newCount, forKey: journalCountKey)
        debugLog("📓 EntitlementManager: Journal insight \(newCount)/\(maxDailyJournalInsights)")
    }
    
    // MARK: - Alert Messaging
    
    var limitAlertTitle: String {
        "Daily Limit Reached"
    }
    
    var limitAlertMessage: String {
        switch usageLimitSource {
        case .chatMessages:
            return "You've used all \(maxDailyChatMessages) chat messages for today. Your limit resets at midnight — come back tomorrow! 🌙"
        case .aiGeneration:
            return "You've created \(maxDailyAIGenerations) AI affirmation sets today. Your limit resets at midnight — come back tomorrow! ✨"
        case .journalInsights:
            return "You've used all \(maxDailyJournalInsights) journal AI insights for today. Your limit resets at midnight — come back tomorrow! 📝"
        case .none:
            return "You've reached your daily limit. Come back tomorrow!"
        }
    }
    
    // MARK: - Private Helpers
    
    private func showLimitReached(source: UsageLimitSource) {
        debugLog("⚠️ EntitlementManager: Daily limit reached for \(source.rawValue)")
        self.usageLimitSource = source
        self.showUsageLimitAlert = true
    }
    
    private func resetDailyCountsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReset = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date ?? .distantPast
        let lastResetDay = Calendar.current.startOfDay(for: lastReset)
        
        if today > lastResetDay {
            UserDefaults.standard.set(0, forKey: chatCountKey)
            UserDefaults.standard.set(0, forKey: aiGenCountKey)
            UserDefaults.standard.set(0, forKey: journalCountKey)
            UserDefaults.standard.set(today, forKey: lastResetDateKey)
            debugLog("🔄 EntitlementManager: Daily usage counts reset")
        }
    }
}
