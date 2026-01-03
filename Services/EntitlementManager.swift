import Foundation
import SwiftUI
import Combine
import SuperwallKit

/// Manages user entitlements and feature access
/// Freemium Logic:
/// 1. 3 free immersive affirmation sessions total
/// 2. AI Generation features require premium
/// 3. All other features (browse, habits, etc.) are free
/// 4. Integration point for Superwall
@MainActor
class EntitlementManager: NSObject, ObservableObject, SuperwallDelegate {
    static let shared = EntitlementManager()
    
    // MARK: - Published State
    @Published var isPremium: Bool = false
    @Published var freeSessionsUsed: Int = 0
    @Published var showPaywall: Bool = false 
    @Published var paywallSource: PaywallSource? = nil 
    
    // MARK: - Configuration
    private let maxFreeSessions = 7 // Total free immersive sessions before paywall
    private let maxDailyAIGenerations = 50 
    
    // MARK: - Computed Properties
    var remainingFreeSessions: Int {
        max(0, maxFreeSessions - freeSessionsUsed)
    }
    
    var hasUsedAllFreeSessions: Bool {
        freeSessionsUsed >= maxFreeSessions
    }
    
    // MARK: - Paywall & Lock Sources
    enum PaywallSource: String {
        case sessionLimit = "session_limit_reached"
        case aiGeneration = "ai_generation_locked"
        case settings = "settings_upgrade"
        case dailyLimitReached = "fair_use_limit_reached" 
        case onboarding = "onboarding_complete"
    }
    
    private var isSuperwallConfigured = false
    
    private override init() {
        super.init()
        loadSessionCount()
        // Don't configure Superwall immediately - delay until needed
        // This avoids the "Sign in to Apple Account" prompt on launch
    }
    
    /// Call this to ensure Superwall is configured before using it
    func ensureSuperwallConfigured() {
        guard !isSuperwallConfigured else { return }
        isSuperwallConfigured = true
        
        let apiKey = "pk_NIuAHj9ov9Bnh1BvWBglk"
        Superwall.configure(apiKey: apiKey)
        Superwall.shared.delegate = self
        print("🧱 EntitlementManager: Superwall configured")
    }
    
    // MARK: - Persistence
    private let freeSessionsKey = "freeSessionsUsed"
    
    private func loadSessionCount() {
        freeSessionsUsed = UserDefaults.standard.integer(forKey: freeSessionsKey)
        print("📊 EntitlementManager: Loaded \(freeSessionsUsed)/\(maxFreeSessions) free sessions used")
    }
    
    private func saveSessionCount() {
        UserDefaults.standard.set(freeSessionsUsed, forKey: freeSessionsKey)
    }
    
    // MARK: - SuperwallDelegate
    
    func subscriptionStatusDidChange(to status: SubscriptionStatus) {
        print("💎 EntitlementManager: Subscription status changed to \(status)")
        
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
    
    /// Check if user can start an immersive session
    /// Returns true if allowed, false if paywall should show
    func canPlaySession() -> Bool {
        if isPremium { return true }
        
        if freeSessionsUsed < maxFreeSessions {
            return true
        } else {
            triggerPaywall(source: .sessionLimit)
            return false
        }
    }
    
    /// Call this AFTER a session is completed to increment usage
    func recordSessionPlayed() {
        if !isPremium {
            freeSessionsUsed += 1
            saveSessionCount()
            print("📊 EntitlementManager: Session recorded. \(freeSessionsUsed)/\(maxFreeSessions) free sessions used")
        }
    }
    
    /// Check if user can use AI features (generation, chat)
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
        
        // Ensure Superwall is configured before using it
        ensureSuperwallConfigured()
        
        Superwall.shared.register(placement: source.rawValue) { [weak self] in
             print("✅ Feature Block Executed")
             self?.isPremium = true
        }
    }
    
    func debugTogglePremium() {
        isPremium.toggle()
        print("🔧 EntitlementManager: Premium status set to \(isPremium)")
    }
    
    func debugResetFreeSessions() {
        freeSessionsUsed = 0
        saveSessionCount()
        print("🔧 EntitlementManager: Free sessions reset to 0")
    }
}
