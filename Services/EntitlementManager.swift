import Foundation
import SwiftUI
import Combine
import SuperwallKit

/// Manages user entitlements and feature access
/// Logic:
/// 1. 10 free sessions per rolling 7-day period
/// 2. AI Generation features are LOCKED for free users
/// 3. Integration point for Superwall
@MainActor
class EntitlementManager: NSObject, ObservableObject, SuperwallDelegate {
    static let shared = EntitlementManager()
    
    // MARK: - Published State
    @Published var isPremium: Bool = false
    @Published var weeklySessionCount: Int = 0
    @Published var showPaywall: Bool = false 
    @Published var paywallSource: PaywallSource? = nil 
    
    // MARK: - Configuration
    private let maxFreeWeeklySessions = 10
    private let maxDailyAIGenerations = 50 
    private let progressService = ProgressService.shared
    
    // MARK: - Paywall & Lock Sources
    enum PaywallSource: String {
        case sessionLimit = "session_limit_reached"
        case aiGeneration = "ai_generation_locked"
        case settings = "settings_upgrade"
        case dailyLimitReached = "fair_use_limit_reached" 
        case onboarding = "onboarding_complete"
    }
    
    private override init() {
        super.init()
        configureSuperwall()
        updateSessionCount()
    }
    
    private func configureSuperwall() {
        // Hardcoded for V1 stability - move back to LocalSecrets when convenient
        let apiKey = "pk_NIuAHj9ov9Bnh1BvWBglk"
        
        // Configure using static method
        Superwall.configure(apiKey: apiKey)
        
        // Set delegate on shared instance
        Superwall.shared.delegate = self
        print("🧱 EntitlementManager: Superwall configured")
    }
    
    // MARK: - SuperwallDelegate
    
    func subscriptionStatusDidChange(to status: SubscriptionStatus) {
        // This delegate method is called whenever the subscription status changes
        print("💎 EntitlementManager: Subscription status changed to \(status)")
        
        // Use pattern matching to avoid 'Binary operator ==' error if the enum has associated values
        if case .active = status {
            self.isPremium = true
        } else {
            self.isPremium = false
        }
    }
    
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        // Optional: tracking logic
    }
    
    // MARK: - Public API
    
    func canPlaySession() -> Bool {
        if isPremium { return true }
        updateSessionCount()
        if weeklySessionCount < maxFreeWeeklySessions {
            return true
        } else {
            triggerPaywall(source: .sessionLimit)
            return false
        }
    }
    
    func canUseAIFeatures() -> Bool {
        if !isPremium {
            triggerPaywall(source: .aiGeneration)
            return false
        }
        if hasReachedDailyLimit() {
            triggerPaywall(source: .dailyLimitReached)
            return false
        }
        return true
    }
    
    func incrementAIGenerationCount() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = defaults.object(forKey: "lastFailedGenerationDate") as? Date,
           !Calendar.current.isDate(lastDate, inSameDayAs: today) {
            defaults.set(0, forKey: "dailyGenerationCount")
        }
        let currentCount = defaults.integer(forKey: "dailyGenerationCount")
        defaults.set(currentCount + 1, forKey: "dailyGenerationCount")
        defaults.set(today, forKey: "lastFailedGenerationDate")
        print("📊 EntitlementManager: AI Generation used. Today: \(currentCount + 1)/\(maxDailyAIGenerations)")
    }
    
    // MARK: - Internal Logic
    
    private func hasReachedDailyLimit() -> Bool {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = defaults.object(forKey: "lastFailedGenerationDate") as? Date,
           !Calendar.current.isDate(lastDate, inSameDayAs: today) {
            defaults.set(0, forKey: "dailyGenerationCount")
            return false
        }
        return defaults.integer(forKey: "dailyGenerationCount") >= maxDailyAIGenerations
    }
    
    func triggerPaywall(source: PaywallSource) {
        print("💰 EntitlementManager: Requesting Paywall for \(source.rawValue)")
        self.paywallSource = source
        
        // Updated to 'register(placement: ...)' for strict V5 SDK compliance
        Superwall.shared.register(placement: source.rawValue) { [weak self] in
             print("✅ Feature Block Executed")
             self?.isPremium = true
        }
    }
    
    func updateSessionCount() {
        let sessions = progressService.getSessionsForLastDays(7)
        self.weeklySessionCount = sessions.reduce(0) { $0 + $1.count }
        print("📊 EntitlementManager: User has consumed \(weeklySessionCount)/\(maxFreeWeeklySessions) free sessions this week.")
    }
    
    func debugTogglePremium() {
        isPremium.toggle()
        print("🔧 EntitlementManager: Premium status set to \(isPremium)")
    }
}
