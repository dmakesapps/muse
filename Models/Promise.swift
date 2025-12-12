import Foundation
import SwiftData

@Model
final class Promise {
    @Attribute(.unique) var id: UUID
    var text: String
    var due: Date
    var kept: Int
    var total: Int
    var createdAt: Date
    var lastKeptAt: Date?
    var notificationMessage: String? // AI-generated personalized message
    var userContext: String? // Why this promise matters to the user
    
    // Track completed notification instances (date + time when each notification was completed)
    var completedNotificationInstances: [Date] = [] // Stores the date/time of each completed notification
    
    // Custom frequency settings (the only way to configure notifications)
    var customDailyTimes: [Date] = [] // Multiple times for daily custom notifications
    var customWeeklyDays: [Int] = [] // Selected weekdays (1=Sunday, 2=Monday, etc.)
    var customWeeklyTimes: [Date] = [] // Up to 5 times for weekly custom notifications
    var customMonthlyDay: Int? // Day of month (1-31) for monthly custom notifications
    var customMonthlyTimes: [Date] = [] // Times for monthly custom notifications
    var customMonthlyReminderCount: Int = 1 // How many reminders per month
    
    // Duration settings
    var durationDays: Int? // How long the promise is held (in days). nil means no end date
    
    // Notification agent (optional - if set, generates dynamic notifications)
    var notificationAgent: NotificationAgent?
    
    var score: Double {
        // For promises with duration, show time-based progress
        if let durationDays = durationDays, durationDays > 0 {
            let calendar = Calendar.current
            let now = Date()
            let daysElapsed = calendar.dateComponents([.day], from: createdAt, to: now).day ?? 0
            
            // Calculate progress: days elapsed / total duration
            let progress = min(Double(daysElapsed) / Double(durationDays) * 100, 100.0)
            return max(progress, 0.0) // Ensure it's not negative
        }
        
        // For promises without duration, show success rate based on completed instances
        // The kept/total is updated when boxes are checked via markNotificationInstanceCompleted
        guard total > 0 else { return 0 }
        return Double(kept) / Double(total) * 100
    }
    
    
    var endDate: Date? {
        guard let durationDays = durationDays else { return nil }
        // Calculate end date from when the promise was created, not from now
        return Calendar.current.date(byAdding: .day, value: durationDays, to: createdAt)
    }
    
    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return Date() > endDate
    }
    
    // Get all notification times configured for this promise
    var allNotificationTimes: [Date] {
        if !customDailyTimes.isEmpty {
            return customDailyTimes
        } else if !customWeeklyTimes.isEmpty {
            return customWeeklyTimes
        } else if !customMonthlyTimes.isEmpty {
            return customMonthlyTimes
        }
        return []
    }
    
    // Check if a specific notification instance (date + time) is completed
    func isNotificationInstanceCompleted(for date: Date) -> Bool {
        let calendar = Calendar.current
        return completedNotificationInstances.contains { completedDate in
            calendar.isDate(completedDate, inSameDayAs: date) &&
            calendar.component(.hour, from: completedDate) == calendar.component(.hour, from: date) &&
            calendar.component(.minute, from: completedDate) == calendar.component(.minute, from: date)
        }
    }
    
    // Mark a notification instance as completed
    func markNotificationInstanceCompleted(for date: Date) {
        let calendar = Calendar.current
        // Check if already completed
        guard !isNotificationInstanceCompleted(for: date) else {
            return // Already completed, don't double-count
        }
        
        // Create a date with the same day and time
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let completedDate = calendar.date(from: components) else {
            return
        }
        
        completedNotificationInstances.append(completedDate)
        // Update kept and total (total represents total opportunities/attempts)
        kept += 1
        total += 1
        lastKeptAt = Date()
    }
    
    // Unmark a notification instance as completed
    func unmarkNotificationInstanceCompleted(for date: Date) {
        let calendar = Calendar.current
        let wasCompleted = isNotificationInstanceCompleted(for: date)
        
        completedNotificationInstances.removeAll { completedDate in
            calendar.isDate(completedDate, inSameDayAs: date) &&
            calendar.component(.hour, from: completedDate) == calendar.component(.hour, from: date) &&
            calendar.component(.minute, from: completedDate) == calendar.component(.minute, from: date)
        }
        
        // Update kept and total if it was actually completed
        if wasCompleted {
            if kept > 0 {
                kept -= 1
            }
            if total > 0 {
                total -= 1
            }
        }
    }
    
    init(text: String, due: Date, context: String? = nil) {
        self.id = UUID()
        self.text = text
        self.due = due
        self.kept = 0
        self.total = 1
        self.createdAt = Date()
        self.userContext = context
    }
}

// MARK: - Date Utilities
struct DateUtils {
    static let calendar = Calendar.current
    
    static func defaultTime() -> Date {
        calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    static func timeComponents(from date: Date) -> (hour: Int, minute: Int) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 9, components.minute ?? 0)
    }
    
    static func calculateNextDueDate(for promise: Promise) -> Date {
        let now = Date()
        
        // Daily
        if let firstTime = promise.customDailyTimes.first {
            let (hour, minute) = timeComponents(from: firstTime)
            if let nextDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) {
                // If the time is still in the future today, return today's time
                if nextDate > now {
                    return nextDate
                }
                // Otherwise, return tomorrow's time
                if let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: nextDate) {
                    return tomorrowDate
                }
            }
            // Fallback: return tomorrow at the same time
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        // Weekly
        if let firstTime = promise.customWeeklyTimes.first, !promise.customWeeklyDays.isEmpty {
            let (hour, minute) = timeComponents(from: firstTime)
            let currentWeekday = calendar.component(.weekday, from: now)
            let sortedDays = promise.customWeeklyDays.sorted()
            
            if let nextDay = sortedDays.first(where: { $0 >= currentWeekday }) {
                var nextDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
                let daysToAdd = nextDay - currentWeekday
                if daysToAdd > 0 {
                    nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: nextDate) ?? nextDate
                } else {
                    nextDate = calendar.date(byAdding: .day, value: 7, to: nextDate) ?? nextDate
                }
                return nextDate
            } else if let firstDay = sortedDays.first {
                var nextDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
                let daysToAdd = (7 - currentWeekday) + firstDay
                nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: nextDate) ?? nextDate
                return nextDate
            }
        }
        
        // Monthly
        if let monthlyDay = promise.customMonthlyDay, let firstTime = promise.customMonthlyTimes.first {
            let (hour, minute) = timeComponents(from: firstTime)
            let currentDay = calendar.component(.day, from: now)
            
            if monthlyDay >= currentDay {
                if let targetDate = calendar.date(bySetting: .day, value: monthlyDay, of: now) {
                    var nextDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate) ?? targetDate
                    if nextDate <= now {
                        nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
                    }
                    return nextDate
                }
            } else {
                if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
                   let targetDate = calendar.date(bySetting: .day, value: monthlyDay, of: nextMonth) {
                    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate) ?? targetDate
                }
            }
        }
        
        // Fallback
        return calendar.date(byAdding: .day, value: 1, to: now) ?? now
    }
}


