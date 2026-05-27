import Foundation
import SwiftUI
import RevenueCat

/// Manages user entitlements and feature access
/// Freemium Logic:
/// 1. 3 free immersive affirmation sessions total
/// 2. AI Generation features require premium
/// 3. All other features (browse, habits, etc.) are free
/// 4. RevenueCat CustomerInfo is the premium source of truth
@MainActor
final class EntitlementManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = EntitlementManager()
    
    // MARK: - Published State
    @Published var isPremium: Bool = false
    @Published var freeSessionsUsed: Int = 0
    @Published var showPaywall: Bool = false
    @Published var paywallSource: PaywallSource? = nil
    @Published var paywallPresenter: PaywallPresenter? = nil
    @Published var shouldCompleteOnboarding: Bool = false
    
    // MARK: - Configuration
    private let maxFreeSessions = 7 // Total free immersive sessions before paywall
    private let maxDailyAIGenerations = 50
    private let freeSessionsKey = "freeSessionsUsed"
    private var isRevenueCatConfigured = false
    
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
    
    /// Which view hierarchy should present the paywall (only one at a time).
    enum PaywallPresenter: String {
        case feed
        case practice
        case onboarding
    }

    var isPaywallConfigured: Bool {
        !Self.revenueCatAPIKey.isEmpty && !Self.premiumEntitlementID.isEmpty
    }
    
    private override init() {
        super.init()
        loadSessionCount()
    }
    
    // MARK: - Persistence
    private func loadSessionCount() {
        freeSessionsUsed = UserDefaults.standard.integer(forKey: freeSessionsKey)
        print("📊 EntitlementManager: Loaded \(freeSessionsUsed)/\(maxFreeSessions) free sessions used")
    }
    
    private func saveSessionCount() {
        UserDefaults.standard.set(freeSessionsUsed, forKey: freeSessionsKey)
    }
    
    // MARK: - RevenueCat Configuration

    func configureRevenueCatIfNeeded() {
        guard !isRevenueCatConfigured else { return }
        guard isPaywallConfigured else {
            print("⚠️ EntitlementManager: RevenueCat is missing local configuration")
            return
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.revenueCatAPIKey)
        Purchases.shared.delegate = self
        isRevenueCatConfigured = true
        print("💎 EntitlementManager: RevenueCat configured")
    }

    func refreshCustomerInfo() {
        configureRevenueCatIfNeeded()
        guard isRevenueCatConfigured else { return }

        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                apply(customerInfo: customerInfo)
            } catch {
                print("⚠️ EntitlementManager: Failed to refresh customer info: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo: customerInfo)
        }
    }
    
    // MARK: - Public API
    
    /// Check if user can start an immersive session
    /// Returns true if allowed, false if paywall should show
    func canPlaySession(presenter: PaywallPresenter = .practice) -> Bool {
        if isPremium { return true }

        triggerPaywall(source: .sessionLimit, presenter: presenter)
        return false
    }
    
    func requiresPremium(presenter: PaywallPresenter, source: PaywallSource = .sessionLimit) -> Bool {
        if isPremium { return true }
        triggerPaywall(source: source, presenter: presenter)
        return false
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
    func canUseAIFeatures(presenter: PaywallPresenter = .practice) -> Bool {
        if !isPremium {
            triggerPaywall(source: .aiGeneration, presenter: presenter)
            return false
        }
        if hasReachedDailyLimit() {
            triggerPaywall(source: .dailyLimitReached, presenter: presenter)
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
    
    func triggerPaywall(source: PaywallSource, presenter: PaywallPresenter) {
        print("💰 EntitlementManager: Requesting Paywall for \(source.rawValue) via \(presenter.rawValue)")
        paywallSource = source
        paywallPresenter = presenter
        showPaywall = true
        configureRevenueCatIfNeeded()
    }

    func handlePaywallDismissed(for source: PaywallSource?) {
        print("💰 EntitlementManager: Paywall dismissed for \(source?.rawValue ?? "unknown")")
        showPaywall = false
        paywallSource = nil
        paywallPresenter = nil

        if source == .onboarding {
            shouldCompleteOnboarding = true
        }
    }

    func handlePurchaseCompleted(_ customerInfo: CustomerInfo, for source: PaywallSource?) {
        apply(customerInfo: customerInfo)
        handlePaywallDismissed(for: source)
    }

    func handleRestoreCompleted(_ customerInfo: CustomerInfo, for source: PaywallSource?) {
        apply(customerInfo: customerInfo)
        handlePaywallDismissed(for: source)
    }

    func restorePurchases(from source: PaywallSource? = nil) {
        configureRevenueCatIfNeeded()
        guard isRevenueCatConfigured else { return }

        Task {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                handleRestoreCompleted(customerInfo, for: source)
            } catch {
                print("⚠️ EntitlementManager: Restore failed: \(error.localizedDescription)")
            }
        }
    }

    func consumeOnboardingCompletionRequest() {
        shouldCompleteOnboarding = false
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

    private func apply(customerInfo: CustomerInfo) {
        let hasPremiumEntitlement = customerInfo.entitlements.active[Self.premiumEntitlementID]?.isActive == true
        isPremium = hasPremiumEntitlement
        print("💎 EntitlementManager: Premium entitlement \(Self.premiumEntitlementID) active = \(hasPremiumEntitlement)")
    }

    private static var revenueCatAPIKey: String {
        let localValue = LocalSecrets.revenueCatPublicAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localValue.isEmpty {
            return localValue
        }

        return ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static var premiumEntitlementID: String {
        let localValue = LocalSecrets.revenueCatEntitlementID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localValue.isEmpty {
            return localValue
        }

        let environmentValue = ProcessInfo.processInfo.environment["REVENUECAT_ENTITLEMENT_ID"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return environmentValue?.isEmpty == false ? environmentValue! : "premium"
    }
}
