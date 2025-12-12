import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var relatedPromiseId: UUID?
    
    init(content: String, isUser: Bool, relatedPromiseId: UUID? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.relatedPromiseId = relatedPromiseId
    }
}

