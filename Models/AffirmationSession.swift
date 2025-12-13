import Foundation
import SwiftData

@Model
final class AffirmationSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var duration: TimeInterval // in seconds
    var affirmationCount: Int // number of affirmations completed
    var affirmations: [String] // text of affirmations used
    
    init(date: Date = Date(), duration: TimeInterval, affirmationCount: Int, affirmations: [String] = []) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.affirmationCount = affirmationCount
        self.affirmations = affirmations
    }
}


