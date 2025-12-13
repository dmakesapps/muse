import SwiftUI
import SwiftData
import UserNotifications

@main
struct MuseApp: App {
    init() {
        NotificationManager.requestPermission()
        setupNotificationDelegate()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([Promise.self, Message.self, UserProfile.self, NotificationAgent.self, Affirmation.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let promiseIdString = response.notification.request.content.userInfo["promiseId"] as? String
        guard let promiseIdString = promiseIdString,
              let promiseId = UUID(uuidString: promiseIdString) else {
            completionHandler()
            return
        }
        
        // Handle "I Kept It" action
        if response.actionIdentifier == "KEPT_ACTION" {
            // Post notification to app to handle the completion
            // The notification time can be inferred from when the notification was scheduled
            // We'll use the current time as the completion time
            NotificationCenter.default.post(
                name: NSNotification.Name("PromiseKeptFromNotification"),
                object: nil,
                userInfo: [
                    "promiseId": promiseId,
                    "completionTime": Date()
                ]
            )
        }
        
        completionHandler()
    }
}

