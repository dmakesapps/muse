import Foundation

// MARK: - User Profile Model

/// Stores user preferences, goals, and personalization data for Muse AI
struct MuseUserProfile: Codable {
    // MARK: - Goals & Focus
    var primaryGoal: String?
    var lifeDomains: [LifeDomain] // What areas they're focusing on
    var currentChallenge: String?
    
    // MARK: - Preferences
    var preferredModality: Modality?
    var communicationStyle: CommunicationStyle
    var spiritualOrientation: SpiritualOrientation
    var challengeLevel: ChallengeLevel
    
    // MARK: - Tracked State
    var identifiedLimitingBeliefs: [String]
    var recentMilestones: [String]
    var lastCheckInDate: Date?
    
    init() {
        self.primaryGoal = nil
        self.lifeDomains = []
        self.currentChallenge = nil
        self.preferredModality = nil
        self.communicationStyle = .balanced
        self.spiritualOrientation = .blended
        self.challengeLevel = .gentle
        self.identifiedLimitingBeliefs = []
        self.recentMilestones = []
        self.lastCheckInDate = nil
    }
    
    // MARK: - Enums
    
    enum LifeDomain: String, Codable, CaseIterable {
        case career = "Career & Professional"
        case relationships = "Relationships & Love"
        case health = "Health & Fitness"
        case finances = "Finances & Abundance"
        case spirituality = "Spirituality & Purpose"
        case creativity = "Creativity & Expression"
        case mentalHealth = "Mental Health & Healing"
        case family = "Family & Parenting"
    }
    
    enum Modality: String, Codable, CaseIterable {
        case affirmations = "Affirmations"
        case breathwork = "Breathwork"
        case frequencies = "Frequencies"
        case manifestation = "Manifestation"
        case mixed = "Mixed/All"
    }
    
    enum CommunicationStyle: String, Codable {
        case concise = "Concise"      // Short, direct messages
        case detailed = "Detailed"     // Thorough explanations
        case balanced = "Balanced"     // Default
    }
    
    enum SpiritualOrientation: String, Codable {
        case secular = "Secular"       // Science-only language
        case spiritual = "Spiritual"   // Open to metaphysical concepts
        case blended = "Blended"       // Both science and spirituality
    }
    
    enum ChallengeLevel: String, Codable {
        case gentle = "Gentle"         // Soft, believing affirmations
        case moderate = "Moderate"     // Some stretching
        case bold = "Bold"             // Identity-challenging
    }
}

// MARK: - User Profile Service

class MuseUserProfileService: ObservableObject {
    static let shared = MuseUserProfileService()
    
    @Published var profile: MuseUserProfile {
        didSet {
            saveProfile()
        }
    }
    
    private let profileKey = "museUserProfile"
    
    private init() {
        self.profile = MuseUserProfile()
        loadProfile()
    }
    
    // MARK: - Persistence
    
    private func saveProfile() {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: profileKey)
            debugLog("📋 User profile saved")
        } catch {
            debugLog("❌ Failed to save user profile: \(error)")
        }
    }
    
    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else {
            return
        }
        
        do {
            profile = try JSONDecoder().decode(MuseUserProfile.self, from: data)
            debugLog("📋 User profile loaded")
        } catch {
            debugLog("❌ Failed to load user profile: \(error)")
        }
    }
    
    // MARK: - Update Methods
    
    func setPrimaryGoal(_ goal: String?) {
        profile.primaryGoal = goal
    }
    
    func addLifeDomain(_ domain: MuseUserProfile.LifeDomain) {
        if !profile.lifeDomains.contains(domain) {
            profile.lifeDomains.append(domain)
        }
    }
    
    func setPreferredModality(_ modality: MuseUserProfile.Modality) {
        profile.preferredModality = modality
    }
    
    func addMilestone(_ milestone: String) {
        profile.recentMilestones.append(milestone)
        // Keep only last 10 milestones
        if profile.recentMilestones.count > 10 {
            profile.recentMilestones.removeFirst()
        }
    }
    
    func addLimitingBelief(_ belief: String) {
        if !profile.identifiedLimitingBeliefs.contains(belief) {
            profile.identifiedLimitingBeliefs.append(belief)
        }
    }
    
    func updateLastCheckIn() {
        profile.lastCheckInDate = Date()
    }
}
