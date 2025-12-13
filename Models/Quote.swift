import Foundation

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


