import Foundation
import SwiftData

@Model
final class AffirmationSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var duration: TimeInterval // in seconds
    var affirmationCount: Int // number of affirmations completed
    
    // Store as Data to avoid CoreData/SwiftData array serialization issues
    private var affirmationsData: Data?
    
    // Computed property for easy access
    var affirmations: [String] {
        get {
            guard let data = affirmationsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            affirmationsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(date: Date = Date(), duration: TimeInterval, affirmationCount: Int, affirmations: [String] = []) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.affirmationCount = affirmationCount
        self.affirmationsData = try? JSONEncoder().encode(affirmations)
    }
}
