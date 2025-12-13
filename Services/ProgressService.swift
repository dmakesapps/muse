import Foundation
import SwiftData

@MainActor
class ProgressService: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalSessions: Int = 0
    @Published var totalTime: TimeInterval = 0
    
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        loadProgress()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadProgress()
    }
    
    func logSession(duration: TimeInterval, affirmationCount: Int, affirmations: [String] = []) {
        guard let context = modelContext else { return }
        
        let session = AffirmationSession(
            date: Date(),
            duration: duration,
            affirmationCount: affirmationCount,
            affirmations: affirmations
        )
        
        context.insert(session)
        
        do {
            try context.save()
            loadProgress()
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    func getSessions(from startDate: Date, to endDate: Date) -> [AffirmationSession] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<AffirmationSession>(
            predicate: #Predicate { session in
                session.date >= startDate && session.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
    
    func getAllSessions() -> [AffirmationSession] {
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<AffirmationSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching all sessions: \(error)")
            return []
        }
    }
    
    private func loadProgress() {
        guard let context = modelContext else { return }
        
        let allSessions = getAllSessions()
        
        totalSessions = allSessions.count
        totalTime = allSessions.reduce(0) { $0 + $1.duration }
        
        // Calculate streaks
        let calendar = Calendar.current
        var longestStreakCount = 0
        var currentStreakCount = 0
        
        // Sort sessions by date (newest first)
        let sortedSessions = allSessions.sorted { $0.date > $1.date }
        
        // Calculate current streak (consecutive days from today backwards)
        var checkDate = calendar.startOfDay(for: Date())
        var daysChecked = Set<String>()
        
        for session in sortedSessions {
            let sessionDate = calendar.startOfDay(for: session.date)
            let dateKey = calendar.dateComponents([.year, .month, .day], from: sessionDate)
            
            // Check if this session is on the date we're checking
            if calendar.isDate(sessionDate, inSameDayAs: checkDate) {
                if !daysChecked.contains("\(dateKey.year ?? 0)-\(dateKey.month ?? 0)-\(dateKey.day ?? 0)") {
                    currentStreakCount += 1
                    daysChecked.insert("\(dateKey.year ?? 0)-\(dateKey.month ?? 0)-\(dateKey.day ?? 0)")
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                }
            } else if sessionDate < checkDate {
                // We've passed the date we're checking, move to next day
                while sessionDate < checkDate {
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                }
                if calendar.isDate(sessionDate, inSameDayAs: checkDate) {
                    if !daysChecked.contains("\(dateKey.year ?? 0)-\(dateKey.month ?? 0)-\(dateKey.day ?? 0)") {
                        currentStreakCount += 1
                        daysChecked.insert("\(dateKey.year ?? 0)-\(dateKey.month ?? 0)-\(dateKey.day ?? 0)")
                        checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                    }
                }
            }
        }
        
        // Calculate longest streak
        var longestStreakDays = Set<String>()
        var tempStreak = 0
        var lastDate: Date?
        
        for session in sortedSessions.reversed() {
            let sessionDate = calendar.startOfDay(for: session.date)
            let dateKey = calendar.dateComponents([.year, .month, .day], from: sessionDate)
            let keyString = "\(dateKey.year ?? 0)-\(dateKey.month ?? 0)-\(dateKey.day ?? 0)"
            
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: sessionDate).day ?? 0
                
                if daysBetween == 1 {
                    // Consecutive day
                    if !longestStreakDays.contains(keyString) {
                        longestStreakDays.insert(keyString)
                        tempStreak += 1
                    }
                } else if daysBetween == 0 {
                    // Same day, don't double count
                    continue
                } else {
                    // Streak broken
                    longestStreakCount = max(longestStreakCount, tempStreak)
                    tempStreak = 1
                    longestStreakDays = Set([keyString])
                }
            } else {
                // First session
                longestStreakDays.insert(keyString)
                tempStreak = 1
            }
            
            lastDate = sessionDate
        }
        
        longestStreakCount = max(longestStreakCount, tempStreak)
        currentStreak = currentStreakCount
        longestStreak = longestStreakCount
    }
    
    func getSessionsByDayOfWeek() -> [Int: Int] {
        let allSessions = getAllSessions()
        let calendar = Calendar.current
        var dayCounts: [Int: Int] = [:]
        
        for session in allSessions {
            let weekday = calendar.component(.weekday, from: session.date)
            dayCounts[weekday, default: 0] += 1
        }
        
        return dayCounts
    }
    
    func getSessionsForLastDays(_ days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        
        let sessions = getSessions(from: startDate, to: endDate)
        var dayCounts: [Date: Int] = [:]
        
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            dayCounts[day, default: 0] += 1
        }
        
        // Fill in all days, even if no sessions
        var result: [(date: Date, count: Int)] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            result.append((date: currentDate, count: dayCounts[currentDate] ?? 0))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return result
    }
}

