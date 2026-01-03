import Foundation
import SwiftData

@MainActor
class ProgressService: ObservableObject {
    // MARK: - Shared Singleton
    static let shared = ProgressService()
    
    // MARK: - Published Properties (all UI components read from these)
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalSessions: Int = 0
    @Published var totalTime: TimeInterval = 0
    @Published var todaySessionCount: Int = 0
    @Published var weeklyData: [(date: Date, count: Int)] = [] // Last 7 days of activity
    
    private var modelContext: ModelContext?
    
    // Private init for singleton pattern, but allow creating new instances for previews
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            loadProgress()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadProgress()
    }
    
    /// Call this to refresh all progress data (e.g., after a session is saved)
    func refresh() {
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
            print("✅ ProgressService: Logged session - duration: \(duration)s, affirmations: \(affirmationCount)")
        } catch {
            print("❌ ProgressService: Error saving session: \(error)")
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
        guard let modelContext = modelContext else { 
            print("⚠️ ProgressService: modelContext is nil in getAllSessions")
            return [] 
        }
        
        let descriptor = FetchDescriptor<AffirmationSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            // Handle iCloud/CloudKit sync errors gracefully
            print("⚠️ ProgressService: Error fetching all sessions: \(error.localizedDescription)")
            // Return empty array instead of crashing
            return []
        }
    }
    
    private func loadProgress() {
        guard modelContext != nil else { return }
        
        let allSessions = getAllSessions()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Basic stats
        totalSessions = allSessions.count
        totalTime = allSessions.reduce(0) { $0 + $1.duration }
        
        // Count today's sessions
        todaySessionCount = allSessions.filter { calendar.isDateInToday($0.date) }.count
        
        // Get unique days with sessions (as Date objects, start of day)
        var uniqueDays = Set<Date>()
        for session in allSessions {
            let dayStart = calendar.startOfDay(for: session.date)
            uniqueDays.insert(dayStart)
        }
        
        // Sort days from newest to oldest
        let sortedDays = uniqueDays.sorted(by: >)
        
        // Calculate current streak (consecutive days from today or yesterday backwards)
        var currentStreakCount = 0
        var checkDate = today
        
        // If no session today, start checking from yesterday (streak can still be active)
        if !uniqueDays.contains(today) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                checkDate = yesterday
            }
        }
        
        for day in sortedDays {
            if calendar.isDate(day, inSameDayAs: checkDate) {
                currentStreakCount += 1
                // Move to previous day
                if let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                    checkDate = prevDay
                }
            } else if day < checkDate {
                // We skipped a day - streak is broken
                break
            }
            // If day > checkDate, continue looking (shouldn't happen with sorted desc)
        }
        
        // Calculate longest streak
        var longestStreakCount = 0
        var tempStreak = 0
        var previousDay: Date?
        
        // Sort days from oldest to newest for longest streak calculation
        let sortedDaysAsc = uniqueDays.sorted()
        
        for day in sortedDaysAsc {
            if let prev = previousDay {
                let daysBetween = calendar.dateComponents([.day], from: prev, to: day).day ?? 0
                
                if daysBetween == 1 {
                    // Consecutive day
                    tempStreak += 1
                } else if daysBetween > 1 {
                    // Gap - streak broken
                    longestStreakCount = max(longestStreakCount, tempStreak)
                    tempStreak = 1
                }
                // daysBetween == 0 shouldn't happen since we're using a Set
            } else {
                // First day
                tempStreak = 1
            }
            previousDay = day
        }
        
        // Don't forget the final streak
        longestStreakCount = max(longestStreakCount, tempStreak)
        
        // Update published properties
        currentStreak = currentStreakCount
        longestStreak = longestStreakCount
        
        // Update weekly data for the weekly progress row (Mon-Sun of current week)
        weeklyData = getSessionsForCurrentWeek()
        
        print("📊 ProgressService: Loaded - sessions: \(totalSessions), currentStreak: \(currentStreak), longestStreak: \(longestStreak), todayCount: \(todaySessionCount)")
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
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return []
        }
        
        // Get sessions from startDate through END of today (to include today's sessions)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let sessions = getSessions(from: startDate, to: endOfToday)
        var dayCounts: [Date: Int] = [:]
        
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            dayCounts[day, default: 0] += 1
        }
        
        // Fill in all days, even if no sessions
        var result: [(date: Date, count: Int)] = []
        var currentDate = startDate
        
        while currentDate <= today {
            result.append((date: currentDate, count: dayCounts[currentDate] ?? 0))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return result
    }
    
    /// Get sessions for the current week (Monday through Sunday)
    func getSessionsForCurrentWeek() -> [(date: Date, count: Int)] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2
        
        let today = calendar.startOfDay(for: Date())
        
        // Find Monday of the current week
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }
        let monday = weekInterval.start
        
        // Get Sunday (6 days after Monday)
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else {
            return []
        }
        
        // Get sessions for the entire week (include future dates with 0 counts)
        let endOfSunday = calendar.date(byAdding: .day, value: 1, to: sunday) ?? sunday
        let sessions = getSessions(from: monday, to: endOfSunday)
        
        var dayCounts: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            dayCounts[day, default: 0] += 1
        }
        
        // Build array from Monday to Sunday
        var result: [(date: Date, count: Int)] = []
        var currentDate = monday
        
        for _ in 0..<7 {
            result.append((date: currentDate, count: dayCounts[currentDate] ?? 0))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return result
    }
}

