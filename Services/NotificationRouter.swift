import Foundation
import UserNotifications

// MARK: - Notification deep linking

final class NotificationRouter: ObservableObject {
    static let shared = NotificationRouter()
    
    static let museTypeKey = "museType"
    static let contentTextKey = "contentText"
    static let sessionTypeKey = "sessionType"
    
    static let typeAffirmation = "affirmation"
    static let typeQuote = "quote"
    static let typeSession = "session"
    
    enum Destination: Equatable {
        case affirmation(text: String)
        case quote(text: String)
        case practiceSession(NotificationService.SessionType)
    }
    
    @Published private(set) var pendingDestination: Destination?
    
    private init() {}
    
    func configure() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        handle(userInfo: response.notification.request.content.userInfo)
    }
    
    func handle(userInfo: [AnyHashable: Any]) {
        guard let museType = userInfo[Self.museTypeKey] as? String else { return }
        
        let destination: Destination?
        switch museType {
        case Self.typeAffirmation:
            guard let text = userInfo[Self.contentTextKey] as? String else { return }
            destination = .affirmation(text: text)
        case Self.typeQuote:
            guard let text = userInfo[Self.contentTextKey] as? String else { return }
            destination = .quote(text: text)
        case Self.typeSession:
            guard let sessionRaw = userInfo[Self.sessionTypeKey] as? String else { return }
            destination = Self.destination(forSessionTypeRaw: sessionRaw)
        default:
            destination = nil
        }
        
        guard let destination else { return }
        
        DispatchQueue.main.async {
            self.pendingDestination = destination
        }
    }
    
    func clearPending() {
        pendingDestination = nil
    }
    
    private static func destination(forSessionTypeRaw sessionRaw: String) -> Destination? {
        let lowered = sessionRaw.lowercased()
        for sessionType in NotificationService.SessionType.allCases {
            if sessionType.rawValue.lowercased() == lowered {
                return .practiceSession(sessionType)
            }
        }
        return nil
    }
    
    static func userInfo(for affirmation: Affirmation) -> [String: Any] {
        [
            museTypeKey: typeAffirmation,
            contentTextKey: affirmation.text
        ]
    }
    
    static func userInfo(for quote: Quote) -> [String: Any] {
        [
            museTypeKey: typeQuote,
            contentTextKey: quote.text
        ]
    }
    
    static func userInfo(for sessionType: NotificationService.SessionType) -> [String: Any] {
        [
            museTypeKey: typeSession,
            sessionTypeKey: sessionType.rawValue.lowercased()
        ]
    }
}

// MARK: - UNUserNotificationCenterDelegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationRouter.shared.handleNotificationResponse(response)
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
