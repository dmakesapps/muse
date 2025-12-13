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
    
    // Custom decoding to auto-generate ID when loading from JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.category = try container.decode(String.self, forKey: .category)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, category
    }
}


