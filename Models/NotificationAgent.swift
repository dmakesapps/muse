import Foundation
import SwiftData

@Model
final class NotificationAgent {
    @Attribute(.unique) var id: UUID
    var name: String
    var personalityDescription: String // User's description of the agent
    var systemPrompt: String // Claude-generated system prompt for this agent
    var createdAt: Date
    var promises: [Promise] = [] // Many-to-many relationship with promises
    
    init(name: String, personalityDescription: String, systemPrompt: String) {
        self.id = UUID()
        self.name = name
        self.personalityDescription = personalityDescription
        self.systemPrompt = systemPrompt
        self.createdAt = Date()
    }
}










