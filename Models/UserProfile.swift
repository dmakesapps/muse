import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String?
    var timezone: String
    var totalPromises: Int
    var totalKept: Int
    var conversationContext: String // Running summary of user's goals and patterns
    
    var overallScore: Double {
        guard totalPromises > 0 else { return 0 }
        return Double(totalKept) / Double(totalPromises) * 100
    }
    
    init() {
        self.id = UUID()
        self.timezone = TimeZone.current.identifier
        self.totalPromises = 0
        self.totalKept = 0
        self.conversationContext = ""
    }
}

