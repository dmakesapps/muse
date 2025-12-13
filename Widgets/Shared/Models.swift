import Foundation

// MARK: - Shared Models for Widget Extension
// These need to be duplicated in the widget extension since it can't import the main app's models directly

struct Quote: Identifiable, Codable {
    let id: UUID
    let text: String
    let author: String
    let category: String
    
    init(id: UUID = UUID(), text: String, author: String, category: String) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
    }
}

struct Affirmation: Identifiable, Codable {
    let id: UUID
    let text: String
    let category: String
    
    init(id: UUID = UUID(), text: String, category: String) {
        self.id = id
        self.text = text
        self.category = category
    }
}


