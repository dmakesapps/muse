import Foundation

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


