import UserNotifications
import Foundation

struct NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            // Permission requested
        }
    }
    
    private static var categorySetup = false
    
    static func schedule(
        for promise: Promise,
        with customMessage: String? = nil,
        userProfile: UserProfile? = nil
    ) {
        // Check notification permissions first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ Notification permission not granted. Status: \(settings.authorizationStatus.rawValue)")
                // Request permission if not authorized
                requestPermission()
                return
            }
            
            // Setup notification category once
            if !categorySetup {
                let keptAction = UNNotificationAction(
                    identifier: "KEPT_ACTION",
                    title: "I Kept It! ✓",
                    options: [.foreground]
                )
                let snoozeAction = UNNotificationAction(
                    identifier: "SNOOZE_ACTION",
                    title: "Remind Me Later",
                    options: []
                )
                let category = UNNotificationCategory(
                    identifier: "PROMISE_ACTION",
                    actions: [keptAction, snoozeAction],
                    intentIdentifiers: []
                )
                UNUserNotificationCenter.current().setNotificationCategories([category])
                categorySetup = true
            }
            
            // If agent exists and no custom message provided, generate one asynchronously
            if let agent = promise.notificationAgent, customMessage == nil, let profile = userProfile {
                Task {
                    do {
                        let agentMessage = try await generateAgentNotificationMessage(
                            for: promise,
                            agent: agent,
                            userProfile: profile
                        )
                        scheduleCustomNotification(for: promise, with: agentMessage)
                    } catch {
                        print("⚠️ Failed to generate agent message: \(error.localizedDescription)")
                        scheduleCustomNotification(for: promise, with: nil)
                    }
                }
            } else {
                scheduleCustomNotification(for: promise, with: customMessage)
            }
        }
    }
    
    private static func scheduleCustomNotification(for promise: Promise, with customMessage: String?) {
        let calendar = Calendar.current
        
        // If promise has an agent, we'll generate dynamic content per notification
        // For now, we'll use the agent to generate a message when scheduling
        // (Note: For truly dynamic content at delivery time, we'd need a Notification Service Extension)
        let content = createNotificationContent(for: promise, with: customMessage)
        
        // Daily
        if !promise.customDailyTimes.isEmpty {
            for (index, time) in promise.customDailyTimes.enumerated() {
                let (hour, minute) = DateUtils.timeComponents(from: time)
                
                // Validate hour and minute
                guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else {
                    print("⚠️ Invalid time components for daily notification: hour=\(hour), minute=\(minute)")
                    continue
                }
                
                // Simply schedule a recurring daily notification
                // UNCalendarNotificationTrigger with hour/minute will fire at the next occurrence
                // If time is in future today, it fires today. If time passed, it fires tomorrow.
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "\(promise.id.uuidString)_daily_\(index)"
                scheduleNotification(identifier: identifier, content: content, trigger: trigger)
            }
        }
        // Weekly
        else if !promise.customWeeklyDays.isEmpty && !promise.customWeeklyTimes.isEmpty {
            for weekday in promise.customWeeklyDays {
                // Validate weekday (1-7, where 1=Sunday)
                guard weekday >= 1 && weekday <= 7 else {
                    print("⚠️ Invalid weekday (\(weekday)) for promise: \(promise.id)")
                    continue
                }
                
                for (timeIndex, time) in promise.customWeeklyTimes.enumerated() {
                    let (hour, minute) = DateUtils.timeComponents(from: time)
                    
                    // Validate hour and minute
                    guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else {
                        print("⚠️ Invalid time components for weekly notification: hour=\(hour), minute=\(minute)")
                        continue
                    }
                    
                    // Schedule recurring notification
                    // With only weekday/hour/minute, it will fire at the next occurrence
                    var dateComponents = DateComponents()
                    dateComponents.weekday = weekday
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let identifier = "\(promise.id.uuidString)_weekly_\(weekday)_\(timeIndex)"
                    scheduleNotification(identifier: identifier, content: content, trigger: trigger)
                }
            }
        }
        // Monthly
        else if let monthlyDay = promise.customMonthlyDay, !promise.customMonthlyTimes.isEmpty {
            // Validate monthly day (1-31)
            guard monthlyDay >= 1 && monthlyDay <= 31 else {
                print("⚠️ Invalid monthly day (\(monthlyDay)) for promise: \(promise.id)")
                return
            }
            
            for (timeIndex, time) in promise.customMonthlyTimes.enumerated() {
                let (hour, minute) = DateUtils.timeComponents(from: time)
                
                // Validate hour and minute
                guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else {
                    print("⚠️ Invalid time components for monthly notification: hour=\(hour), minute=\(minute)")
                    continue
                }
                
                for monthOffset in 0..<min(promise.customMonthlyReminderCount, 12) {
                    var dateComponents = DateComponents()
                    dateComponents.day = monthlyDay
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    if let targetDate = calendar.date(byAdding: .month, value: monthOffset, to: Date()) {
                        dateComponents.month = calendar.component(.month, from: targetDate)
                        dateComponents.year = calendar.component(.year, from: targetDate)
                        
                        let maxDay = calendar.range(of: .day, in: .month, for: targetDate)?.count ?? 31
                        if monthlyDay > maxDay {
                            dateComponents.day = maxDay
                        }
                    }
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let identifier = "\(promise.id.uuidString)_monthly_\(monthOffset)_\(timeIndex)"
                    scheduleNotification(identifier: identifier, content: content, trigger: trigger)
                }
            }
        }
    }
    
    private static func scheduleNotification(identifier: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger) {
        // Validate trigger
        guard let calendarTrigger = trigger as? UNCalendarNotificationTrigger else {
            print("⚠️ Invalid trigger type for notification: \(identifier)")
            return
        }
        
        // Validate date components
        let dateComponents = calendarTrigger.dateComponents
        if let hour = dateComponents.hour, (hour < 0 || hour > 23) {
            print("⚠️ Invalid hour (\(hour)) for notification: \(identifier)")
            return
        }
        if let minute = dateComponents.minute, (minute < 0 || minute > 59) {
            print("⚠️ Invalid minute (\(minute)) for notification: \(identifier)")
            return
        }
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification \(identifier): \(error.localizedDescription)")
            } else {
                print("✅ Successfully scheduled notification: \(identifier)")
            }
        }
    }
    
    private static func createNotificationContent(for promise: Promise, with customMessage: String?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Validate promise text is not empty
        guard !promise.text.isEmpty else {
            print("⚠️ Promise text is empty, cannot create notification")
            content.title = "Reminder"
            content.body = "Time to keep your promise!"
            return content
        }
        
        // Use the promise text as the notification title
        content.title = promise.text
        
        // Priority: customMessage > static notificationMessage > promise text
        // Note: Agent messages are generated asynchronously in schedule() and passed as customMessage
        if let customMessage = customMessage, !customMessage.isEmpty {
            content.body = customMessage
        } else if let notificationMessage = promise.notificationMessage, !notificationMessage.isEmpty {
            content.body = notificationMessage
        } else {
            // If no custom message, use a default reminder message
            content.body = "Time to keep your promise!"
        }
        
        // Ensure body is not empty
        if content.body.isEmpty {
            content.body = "Time to keep your promise!"
        }
        
        content.sound = .default
        content.categoryIdentifier = "PROMISE_ACTION"
        content.userInfo = ["promiseId": promise.id.uuidString]
        
        // Add agent info if present
        if let agent = promise.notificationAgent {
            content.userInfo["agentId"] = agent.id.uuidString
        }
        
        return content
    }
    
    // Generate notification message using agent's system prompt
    // This will be called when scheduling notifications with agents
    static func generateAgentNotificationMessage(
        for promise: Promise,
        agent: NotificationAgent,
        userProfile: UserProfile
    ) async throws -> String {
        // This will use AICoachService to generate a unique message
        // using the agent's system prompt
        return try await AICoachService.generateNotificationWithAgent(
            for: promise,
            agent: agent,
            userProfile: userProfile
        )
    }
    
    static func cancel(for promise: Promise) {
        // Get all pending notifications and filter by promise ID
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.contains(promise.id.uuidString) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }
    
    static func handleNotificationAction(
        _ actionIdentifier: String,
        promiseId: UUID,
        completion: @escaping (Bool) -> Void
    ) {
        // This will be called from AppDelegate/SceneDelegate
        switch actionIdentifier {
        case "KEPT_ACTION":
            completion(true) // Mark as kept
        case "SNOOZE_ACTION":
            completion(false) // Snooze for 1 hour
        default:
            break
        }
    }
    
    // MARK: - Debug/Verification Helpers
    static func getPendingNotifications(for promise: Promise, completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let promiseNotifications = requests.filter { $0.identifier.contains(promise.id.uuidString) }
            print("📋 Found \(promiseNotifications.count) pending notifications for promise: \(promise.id)")
            completion(promiseNotifications)
        }
    }
    
    static func getAllPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📊 Total pending notifications: \(requests.count) (iOS limit: 64)")
            if requests.count >= 64 {
                print("⚠️ WARNING: Approaching iOS notification limit (64). Some notifications may not be scheduled.")
            }
            completion(requests)
        }
    }
    
    static func checkNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            print("📱 Notification authorization status: \(settings.authorizationStatus.rawValue) (authorized: \(isAuthorized))")
            if !isAuthorized {
                print("⚠️ Notifications will not be delivered until permission is granted")
            }
            completion(isAuthorized)
        }
    }
}


