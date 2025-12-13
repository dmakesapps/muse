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
    
    // Custom decoding to auto-generate ID when loading from JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.author = try container.decode(String.self, forKey: .author)
        self.category = try container.decode(String.self, forKey: .category)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, author, category
    }
}


