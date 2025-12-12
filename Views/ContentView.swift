import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Promise.due) private var promises: [Promise]
    @Environment(\.modelContext) private var modelContext
    
    // Create a persistent ViewModel that survives tab switches
    @State private var chatViewModel: ChatViewModel?
    
    private var profile: UserProfile {
        if let existing = profiles.first {
            return existing
        } else {
            let new = UserProfile()
            modelContext.insert(new)
            return new
        }
    }
    
    @State private var navigationPath = NavigationPath()
    @State private var showSidebar = false
    @State private var isDarkMode = false
    @State private var showAgentCreation = false
    @State private var showHelp = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ChatView(
                viewModel: chatViewModel ?? createViewModel(),
                navigationPath: $navigationPath,
                showSidebar: $showSidebar,
                isDarkMode: $isDarkMode,
                showAgentCreation: $showAgentCreation,
                showHelp: $showHelp
            )
            .navigationDestination(for: String.self) { destination in
                if destination == "promises" {
                    PromiseListView(isDarkMode: $isDarkMode)
                } else if destination == "schedule" {
                    ScheduleView(isDarkMode: $isDarkMode)
                }
            }
        }
        .overlay(alignment: .leading) {
            SidebarView(
                isPresented: $showSidebar,
                isDarkMode: isDarkMode,
                onToggleDarkMode: { isDarkMode.toggle() },
                onShowAgentCreation: {
                    showAgentCreation = true
                },
                onNavigateToPromises: {
                    navigationPath.append("promises")
                },
                onNavigateToSchedule: {
                    navigationPath.append("schedule")
                }
            )
            .allowsHitTesting(showSidebar)
        }
        .sheet(isPresented: $showAgentCreation) {
            AgentCreationSheet(isDarkMode: $isDarkMode)
        }
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                HelpView(isDarkMode: $isDarkMode)
            }
        }
        .onAppear {
            // Create ViewModel only once when app appears
            if chatViewModel == nil {
                chatViewModel = createViewModel()
            } else {
                // Update promises in existing ViewModel when they change
                chatViewModel?.updatePromises(promises)
            }
        }
        .onChange(of: promises.count) { oldValue, newValue in
            // Update ViewModel when promises change (new promise created)
            chatViewModel?.updatePromises(promises)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PromiseKeptFromNotification"))) { notification in
            handlePromiseKeptFromNotification(notification: notification)
        }
    }
    
    private func handlePromiseKeptFromNotification(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let promiseId = userInfo["promiseId"] as? UUID,
              let completionTime = userInfo["completionTime"] as? Date else {
            return
        }
        
        // Find the promise
        if let promise = promises.first(where: { $0.id == promiseId }) {
            // Determine which notification time this corresponds to
            // We'll match based on the hour and minute of the completion time
            let calendar = Calendar.current
            let completionHour = calendar.component(.hour, from: completionTime)
            let completionMinute = calendar.component(.minute, from: completionTime)
            
            // Find matching notification time
            let notificationTimes = promise.allNotificationTimes
            for notificationTime in notificationTimes {
                let (hour, minute) = DateUtils.timeComponents(from: notificationTime)
                if hour == completionHour && minute == completionMinute {
                    // Create a date for today at this notification time
                    let todayAtTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                    
                    // Mark this instance as completed
                    promise.markNotificationInstanceCompleted(for: todayAtTime)
                    
                    // Update profile
                    profile.totalKept += 1
                    
                    // Recalculate next due date
                    promise.due = DateUtils.calculateNextDueDate(for: promise)
                    
                    // Cancel old notifications and schedule new ones
                    NotificationManager.cancel(for: promise)
                    
                    Task {
                        do {
                            if promise.notificationAgent != nil {
                                NotificationManager.schedule(for: promise, with: nil, userProfile: profile)
                            } else {
                                let newMessage = try await AICoachService.generateNotificationMessage(
                                    for: promise,
                                    userProfile: profile
                                )
                                promise.notificationMessage = newMessage
                                NotificationManager.schedule(for: promise, with: newMessage, userProfile: profile)
                            }
                        } catch {
                            NotificationManager.schedule(for: promise, with: nil, userProfile: profile)
                        }
                    }
                    
                    // Save changes
                    try? modelContext.save()
                    break
                }
            }
        }
    }
    
    private func createViewModel() -> ChatViewModel {
        ChatViewModel(
            modelContext: modelContext,
            profile: profile,
            promises: promises
        )
    }
}

