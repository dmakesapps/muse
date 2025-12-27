import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressService = ProgressService.shared
    
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    // To-Do List State
    @State private var tasks: [DailyTask] = [] // Start empty
    @State private var showAddTaskSheet = false
    @State private var newTaskTitle = ""
    @State private var expandedTaskId: UUID? // accordion logic
    
    // Icons for selection
    let availableIcons = ["bed.double.fill", "dumbbell.fill", "figure.mind.and.body", "figure.walk", "leaf.fill", "drop.fill", "book.fill", "pencil", "star.fill"]
    @State private var selectedIcon = "star.fill"
    
    // Notification settings
    @State private var showNotificationSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MuseBackgroundView(selectedBackground: selectedBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Header (Notification, Date, Add)
                        HStack {
                            Button(action: { showNotificationSettings = true }) {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundStyle(.white, .red)
                                    .font(.system(size: 20))
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("Today")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Text(Date().formatted(.dateTime.weekday(.wide).day().month()))
                                    .font(.system(size: 12))
                                    .foregroundColor(.museLightGray)
                            }
                            
                            Spacer()
                            
                            // Add Task Button
                            Button(action: { showAddTaskSheet = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold)) // Bolder add button
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
                        // 2. Weekly Progress Row (Data Driven)
                        // Using real data from ProgressService
                        WeeklyProgressRow(progressService: progressService)
                            .padding(.horizontal, 20)
                        
                        // 3. Key Metrics (Restored)
                        // Shows streaks, time, etc.
                        KeyMetricsView(
                            totalSessions: progressService.totalSessions,
                            totalTime: progressService.totalTime,
                            currentStreak: progressService.currentStreak
                        )
                        .padding(.horizontal, 20)
                        
                        // 4. Task List (The Main Feature)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("My Habits")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.leading, 4)
                            
                            if tasks.isEmpty {
                                // Empty State
                                VStack(spacing: 16) {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 40))
                                        .foregroundColor(.museLightGray.opacity(0.5))
                                    Text("No tasks yet. Tap + to add one!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.museLightGray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(30)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.2)))
                            } else {
                                ForEach($tasks) { $task in
                                    TaskRow(
                                        task: $task,
                                        isExpanded: expandedTaskId == task.id,
                                        onExpand: {
                                            withAnimation(.spring()) {
                                                if expandedTaskId == task.id {
                                                    expandedTaskId = nil
                                                } else {
                                                    expandedTaskId = task.id
                                                }
                                            }
                                        },
                                        onDelete: {
                                            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                                withAnimation {
                                                    tasks.remove(at: index)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 5. History / Calendar
                        VStack(alignment: .leading, spacing: 12) {
                            Text("History")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            ContributionCalendarView(progressService: progressService)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 6. Legal Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Legal")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: PrivacyPolicyView()) {
                                    HStack {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(.museLightGray)
                                            .frame(width: 24)
                                        Text("Privacy Policy")
                                            .foregroundColor(.museSoftWhite)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.museLightGray)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                                
                                Divider().background(Color.museMediumGray)
                                
                                NavigationLink(destination: TermsOfServiceView()) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.museLightGray)
                                            .frame(width: 24)
                                        Text("Terms of Service")
                                            .foregroundColor(.museSoftWhite)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.museLightGray)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                                
                                Divider().background(Color.museMediumGray)
                                
                                NavigationLink(destination: EULAView()) {
                                    HStack {
                                        Image(systemName: "signature")
                                            .foregroundColor(.museLightGray)
                                            .frame(width: 24)
                                        Text("End User License Agreement")
                                            .foregroundColor(.museSoftWhite)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.museLightGray)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // App Version
                        Text("Muse v1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(.museLightGray)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                        
                        // Spacer for bottom
                        Spacer(minLength: 40)
                    }
                }
                .scrollIndicators(.hidden)
                
                // NO AI BUTTON (Removed as requested)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
            .onAppear {
                progressService.setModelContext(modelContext)
            }
            // Add Task Sheet
            .sheet(isPresented: $showAddTaskSheet) {
                AddTaskSheet(isPresented: $showAddTaskSheet, onAdd: { title, icon in
                    let newTask = DailyTask(
                        icon: icon,
                        title: title,
                        subtitle: "Streak: 0 days", // Initial subtitle
                        isCompleted: false,
                        color: .museAccentBlue // Default color
                    )
                    withAnimation {
                        tasks.insert(newTask, at: 0) // Add to top
                    }
                })
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

// MARK: - Models
struct DailyTask: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    var isCompleted: Bool
    let color: Color
}

// MARK: - Subviews

struct WeeklyProgressRow: View {
    @ObservedObject var progressService: ProgressService
    
    var calendar: Calendar { Calendar.current }
    
    // Use the published weeklyData property so we react to changes
    var weekData: [(date: Date, count: Int)] {
        progressService.weeklyData
    }
    
    var body: some View {
        HStack(spacing: 0) {
            let data = weekData
            // If data is pending (on load), might be empty? getSessionsForLastDays handles it.
            
            ForEach(Array(data.enumerated()), id: \.offset) { index, dayInfo in
                let (date, count) = dayInfo
                let isToday = calendar.isDateInToday(date)
                let weekday = date.formatted(.dateTime.weekday(.narrow)) // M, T, W...
                
                VStack(spacing: 8) {
                    Text(weekday)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isToday ? .white : .museLightGray)
                    
                    ZStack {
                        // Outer Ring (Progress)
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
                            .frame(width: 36, height: 36)
                        
                        // Indicator
                        if count > 0 {
                            // Active Day
                            Circle()
                                .fill(isToday ? Color.musePurple : Color.museAccentBlue.opacity(0.8))
                                .frame(width: 28, height: 28)
                                .shadow(radius: 4)
                        } else {
                             // Inner circle for specific look
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 28, height: 28)
                        }
                        
                        // Today Highlight
                        if isToday {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.museAccentBlue, .musePurple],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 36, height: 36)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct TaskRow: View {
    @Binding var task: DailyTask
    let isExpanded: Bool
    let onExpand: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row
            Button(action: onExpand) {
                HStack(spacing: 16) {
                    // Icon Bubble
                    ZStack {
                        Circle()
                            .fill(task.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: task.icon)
                            .font(.system(size: 18))
                            .foregroundColor(task.color)
                    }
                    
                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.6 : 1)
                        
                        if let subtitle = task.subtitle {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.museLightGray)
                        }
                    }
                    
                    Spacer()
                    
                    // Checkbox (Independent tap)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            task.isCompleted.toggle()
                        }
                    }) {
                        ZStack {
                            if task.isCompleted {
                                Circle()
                                    .fill(LinearGradient(colors: [.musePurple, .museAccentBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 28, height: 28)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .stroke(Color.museLightGray.opacity(0.5), lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.01)) // Hit area
            }
            .buttonStyle(.plain)
            
            // Expanded Content ("Show one at a time")
            if isExpanded {
                VStack(spacing: 12) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        Text("Task Details")
                            .font(.system(size: 14))
                            .foregroundColor(.museLightGray)
                        Spacer()
                        
                        Button(action: onDelete) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.4))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isExpanded ? Color.museAccentBlue.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// Add Task Sheet
struct AddTaskSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, String) -> Void
    
    @State private var title = ""
    @State private var selectedIcon = "star.fill"
    
    let icons = ["star.fill", "bed.double.fill", "dumbbell.fill", "figure.mind.and.body", "book.fill", "pencil", "drop.fill", "leaf.fill", "heart.fill", "flame.fill"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("New Habit")
                .font(.museHeadline())
                .foregroundColor(.white)
                .padding(.top, 20)
            
            TextField("Habit Name (e.g., Read 10 mins)", text: $title)
                .padding()
                .background(Color.museDarkGray)
                .cornerRadius(12)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedIcon == icon ? .white : .museLightGray)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.museAccentBlue : Color.museDarkGray)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: {
                if !title.isEmpty {
                    onAdd(title, selectedIcon)
                    isPresented = false
                }
            }) {
                Text("Create Habit")
                    .font(.museButtonMedium())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(title.isEmpty ? Color.museDarkGray : Color.museAccentBlue)
                    .cornerRadius(16)
            }
            .disabled(title.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            Spacer()
        }
        .background(Color.museDeepNavy)
    }
}

// MARK: - Key Metrics View (Restored)
struct KeyMetricsView: View {
    let totalSessions: Int
    let totalTime: TimeInterval
    let currentStreak: Int
    
    private var formattedTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Sessions",
                value: "\(totalSessions)",
                icon: "checkmark.circle.fill",
                color: .museAccentBlue
            )
            
            MetricCard(
                title: "Time",
                value: formattedTime,
                icon: "clock.fill",
                color: .museTeal
            )
            
            MetricCard(
                title: "Streak",
                value: "\(currentStreak)",
                icon: "flame.fill",
                color: .museOrange
            )
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.museSoftWhite)
            
            Text(title)
                .font(.museCaption())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
        )
    }
}

// MARK: - Contribution Calendar View (Existing)
struct ContributionCalendarView: View {
    let progressService: ProgressService
    
    @State private var offset: Int = 0 
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var currentMonthDate: Date {
        calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate) else { return [] }
        let range = calendar.range(of: .day, in: .month, for: currentMonthDate)!
        return (0..<range.count).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monthInterval.start)
        }
    }
    
    private var startOffset: Int {
        guard let monthStart = calendar.dateInterval(of: .month, for: currentMonthDate)?.start else { return 0 }
        return calendar.component(.weekday, from: monthStart) - 1
    }
    
    private func getSessionCount(for date: Date) -> Int {
        let sessions = progressService.getAllSessions()
        return sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }
    
    private func getIntensityColor(count: Int) -> Color {
        if count == 0 { return Color.museMediumGray.opacity(0.3) }
        else if count == 1 { return Color.museAccentBlue.opacity(0.4) }
        else if count == 2 { return Color.museAccentBlue.opacity(0.7) }
        else { return Color.museAccentBlue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(currentMonthDate.formatted(.dateTime.month().year()))
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { withAnimation { offset -= 1 } }) { Image(systemName: "chevron.left").foregroundColor(.museLightGray) }
                    
                    Button(action: { withAnimation { offset += 1 } }) { Image(systemName: "chevron.right").foregroundColor(offset >= 0 ? .museMediumGray.opacity(0.3) : .museLightGray) }
                        .disabled(offset >= 0)
                }
            }
            
            VStack(spacing: 12) {
                // Day Headers
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day).font(.system(size: 10, weight: .bold)).foregroundColor(.museMediumGray).frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<startOffset, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }
                    
                    ForEach(daysInMonth, id: \.self) { date in
                        let count = getSessionCount(for: date)
                        let isToday = calendar.isDateInToday(date)
                        
                        ZStack {
                            Circle().fill(getIntensityColor(count: count))
                            if isToday { Circle().stroke(Color.museSoftWhite, lineWidth: 1) }
                            Text("\(calendar.component(.day, from: date))").font(.system(size: 10)).foregroundColor(count > 0 ? .white : .museLightGray)
                        }.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.museDarkGray.opacity(0.6))
                .rainbowBorder()
        )
    }
}

#Preview {
    ProgressView()
        .modelContainer(for: [AffirmationSession.self])
}

// MARK: - Notification Service
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var affirmationReminders: [SessionReminder] = []
    @Published var breathworkReminders: [SessionReminder] = []
    @Published var journalReminders: [SessionReminder] = []
    @Published var isAuthorized: Bool = false
    
    // Affirmation Notifications Settings (0 = None, 1-5 = frequency per day)
    @Published var affirmationNotificationCount: Int = 0
    @Published var affirmationCategories: Set<String> = []
    
    // Quote Notifications Settings (0 = None, 1-5 = frequency per day)
    @Published var quoteNotificationCount: Int = 0
    @Published var quoteCategories: Set<String> = []
    
    static let maxReminders = 5
    
    enum SessionType: String, CaseIterable, Codable {
        case affirmations = "Affirmations"
        case breathwork = "Breathwork"
        case journaling = "Journaling"
        
        var icon: String {
            switch self {
            case .affirmations: return "quote.bubble.fill"
            case .breathwork: return "wind"
            case .journaling: return "book.closed.fill"
            }
        }
    }
    
    struct SessionReminder: Identifiable, Codable, Equatable {
        let id: UUID
        var time: Date
        var sessionType: SessionType
        var isEnabled: Bool
        
        init(id: UUID = UUID(), time: Date, sessionType: SessionType, isEnabled: Bool = true) {
            self.id = id
            self.time = time
            self.sessionType = sessionType
            self.isEnabled = isEnabled
        }
    }
    
    private let notificationMessages = [
        "It's time for %@.",
        "Let's do a %@ session.",
        "Ready for your %@ session?"
    ]
    
    private let userDefaultsKey = "sessionReminders"
    private let inspirationKey = "dailyInspirationSettings"
    
    private init() {
        loadReminders()
        loadContentSettings()
        checkAuthorizationStatus()
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Send a test notification in 5 seconds (for testing purposes)
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Muse Test"
        content.body = "If you see this, notifications are working! 🎉"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notisound.wav"))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Test notification error: \(error)")
            } else {
                print("✅ Test notification scheduled for 5 seconds from now")
            }
        }
    }
    
    func addReminder(for sessionType: SessionType, at time: Date) {
        let reminder = SessionReminder(time: time, sessionType: sessionType)
        
        switch sessionType {
        case .affirmations:
            guard affirmationReminders.count < Self.maxReminders else { return }
            affirmationReminders.append(reminder)
        case .breathwork:
            guard breathworkReminders.count < Self.maxReminders else { return }
            breathworkReminders.append(reminder)
        case .journaling:
            guard journalReminders.count < Self.maxReminders else { return }
            journalReminders.append(reminder)
        }
        
        saveReminders()
        scheduleNotification(for: reminder)
    }
    
    func removeReminder(_ reminder: SessionReminder) {
        switch reminder.sessionType {
        case .affirmations:
            affirmationReminders.removeAll { $0.id == reminder.id }
        case .breathwork:
            breathworkReminders.removeAll { $0.id == reminder.id }
        case .journaling:
            journalReminders.removeAll { $0.id == reminder.id }
        }
        
        saveReminders()
        cancelNotification(for: reminder)
    }
    
    func toggleReminder(_ reminder: SessionReminder) {
        var updatedReminder = reminder
        updatedReminder.isEnabled.toggle()
        
        switch reminder.sessionType {
        case .affirmations:
            if let index = affirmationReminders.firstIndex(where: { $0.id == reminder.id }) {
                affirmationReminders[index] = updatedReminder
            }
        case .breathwork:
            if let index = breathworkReminders.firstIndex(where: { $0.id == reminder.id }) {
                breathworkReminders[index] = updatedReminder
            }
        case .journaling:
            if let index = journalReminders.firstIndex(where: { $0.id == reminder.id }) {
                journalReminders[index] = updatedReminder
            }
        }
        
        saveReminders()
        
        if updatedReminder.isEnabled {
            scheduleNotification(for: updatedReminder)
        } else {
            cancelNotification(for: updatedReminder)
        }
    }
    
    func reminders(for sessionType: SessionType) -> [SessionReminder] {
        switch sessionType {
        case .affirmations: return affirmationReminders
        case .breathwork: return breathworkReminders
        case .journaling: return journalReminders
        }
    }
    
    func canAddReminder(for sessionType: SessionType) -> Bool {
        return reminders(for: sessionType).count < Self.maxReminders
    }
    
    private func scheduleNotification(for reminder: SessionReminder) {
        guard reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Muse"
        let message = notificationMessages.randomElement() ?? notificationMessages[0]
        content.body = String(format: message, reminder.sessionType.rawValue.lowercased())
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notisound.wav"))
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification(for reminder: SessionReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    private func saveReminders() {
        let allReminders = affirmationReminders + breathworkReminders + journalReminders
        if let encoded = try? JSONEncoder().encode(allReminders) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([SessionReminder].self, from: data) else { return }
        
        affirmationReminders = decoded.filter { $0.sessionType == .affirmations }
        breathworkReminders = decoded.filter { $0.sessionType == .breathwork }
        journalReminders = decoded.filter { $0.sessionType == .journaling }
    }
    
    // MARK: - Affirmation & Quote Notifications
    
    func updateAffirmationSettings(count: Int, categories: Set<String>) {
        affirmationNotificationCount = count
        affirmationCategories = categories
        saveContentSettings()
        rescheduleContentNotifications()
    }
    
    func updateQuoteSettings(count: Int, categories: Set<String>) {
        quoteNotificationCount = count
        quoteCategories = categories
        saveContentSettings()
        rescheduleContentNotifications()
    }
    
    func rescheduleContentNotifications() {
        // Cancel existing content notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let contentIds = requests.filter { 
                $0.identifier.hasPrefix("affirmation_") || $0.identifier.hasPrefix("quote_") 
            }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: contentIds)
            
            // Schedule new notifications on main thread
            DispatchQueue.main.async {
                self.scheduleAffirmationNotifications()
                self.scheduleQuoteNotifications()
            }
        }
    }
    
    private func scheduleAffirmationNotifications() {
        guard affirmationNotificationCount > 0, !affirmationCategories.isEmpty else { return }
        
        let content = loadAffirmationsContent()
        guard !content.isEmpty else { return }
        
        for i in 0..<affirmationNotificationCount {
            let randomContent = content.randomElement() ?? content[0]
            scheduleContentNotification(
                identifier: "affirmation_\(i)",
                title: "✨ Daily Affirmation",
                body: randomContent,
                index: i,
                totalCount: affirmationNotificationCount
            )
        }
    }
    
    private func scheduleQuoteNotifications() {
        guard quoteNotificationCount > 0, !quoteCategories.isEmpty else { return }
        
        let content = loadQuotesContent()
        guard !content.isEmpty else { return }
        
        for i in 0..<quoteNotificationCount {
            let randomContent = content.randomElement() ?? content[0]
            scheduleContentNotification(
                identifier: "quote_\(i)",
                title: "💭 Daily Quote",
                body: randomContent,
                index: i,
                totalCount: quoteNotificationCount
            )
        }
    }
    
    private func scheduleContentNotification(identifier: String, title: String, body: String, index: Int, totalCount: Int) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName("notisound.wav"))
        
        // Generate random hour between 8 AM and 9 PM, spread throughout the day
        let startHour = 8
        let endHour = 21
        let hoursRange = endHour - startHour
        let spacing = hoursRange / max(totalCount, 1)
        let baseHour = startHour + (spacing * index)
        let hour = min(baseHour + Int.random(in: 0..<max(spacing, 1)), endHour)
        let minute = Int.random(in: 0..<60)
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error: \(error)")
            } else {
                print("✅ Scheduled \(identifier) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    private func loadAffirmationsContent() -> [String] {
        guard let path = Bundle.main.path(forResource: "affirmations", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let affirmations = try? JSONDecoder().decode([Affirmation].self, from: data) else {
            return []
        }
        
        if affirmationCategories.isEmpty {
            return affirmations.map { $0.text }
        } else {
            return affirmations.filter { affirmationCategories.contains($0.category) }.map { $0.text }
        }
    }
    
    private func loadQuotesContent() -> [String] {
        guard let path = Bundle.main.path(forResource: "quotes", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data) else {
            return []
        }
        
        if quoteCategories.isEmpty {
            return quotes.map { "\"\($0.text)\" — \($0.author)" }
        } else {
            return quotes.filter { quoteCategories.contains($0.category) }.map { "\"\($0.text)\" — \($0.author)" }
        }
    }
    
    private func saveContentSettings() {
        let settings: [String: Any] = [
            "affirmationCount": affirmationNotificationCount,
            "affirmationCategories": Array(affirmationCategories),
            "quoteCount": quoteNotificationCount,
            "quoteCategories": Array(quoteCategories)
        ]
        UserDefaults.standard.set(settings, forKey: inspirationKey)
    }
    
    private func loadContentSettings() {
        guard let settings = UserDefaults.standard.dictionary(forKey: inspirationKey) else { return }
        
        affirmationNotificationCount = settings["affirmationCount"] as? Int ?? 0
        quoteNotificationCount = settings["quoteCount"] as? Int ?? 0
        
        if let categories = settings["affirmationCategories"] as? [String] {
            affirmationCategories = Set(categories)
        }
        if let categories = settings["quoteCategories"] as? [String] {
            quoteCategories = Set(categories)
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    @State private var selectedSessionType: NotificationService.SessionType = .affirmations
    @State private var showAddReminder = false
    @State private var newReminderTime = Date()
    
    var body: some View {
        ZStack {
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Text("Reminders")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.museSoftWhite)
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.museSoftWhite)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if !notificationService.isAuthorized {
                            authorizationCard
                        }
                        
                        // Affirmation Notifications Section
                        affirmationsSection
                        
                        // Quote Notifications Section
                        quotesSection
                        
                        Divider()
                            .background(Color.museMediumGray)
                        
                        // Session Reminders Section
                        Text("Session Reminders")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        sessionTypeTabs
                        remindersSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { 
            notificationService.checkAuthorizationStatus()
            loadAllCategories()
        }
        .sheet(isPresented: $showAddReminder) { addReminderSheet }
    }
    
    // MARK: - Content Notification Sections
    
    @State private var affirmationCategories: [String] = []
    @State private var quoteCategories: [String] = []
    
    private func loadAllCategories() {
        // Load affirmation categories
        if let path = Bundle.main.path(forResource: "affirmations", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let items = try? JSONDecoder().decode([Affirmation].self, from: data) {
            affirmationCategories = Array(Set(items.map { $0.category })).sorted()
        }
        
        // Load quote categories
        if let path = Bundle.main.path(forResource: "quotes", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let items = try? JSONDecoder().decode([Quote].self, from: data) {
            quoteCategories = Array(Set(items.map { $0.category })).sorted()
        }
    }
    
    private var affirmationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Affirmation Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.museSoftWhite)
            }
            
            // Frequency Selection (None, 1-5)
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily frequency")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.museLightGray)
                
                HStack(spacing: 6) {
                    ForEach(0...5, id: \.self) { count in
                        Button(action: {
                            notificationService.updateAffirmationSettings(
                                count: count,
                                categories: notificationService.affirmationCategories
                            )
                        }) {
                            Text(count == 0 ? "None" : "\(count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(notificationService.affirmationNotificationCount == count ? .museSoftWhite : .museLightGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(notificationService.affirmationNotificationCount == count ? Color.purple : Color.white.opacity(0.08))
                                )
                        }
                    }
                }
            }
            
            // Category Selection (only show if frequency > 0)
            if notificationService.affirmationNotificationCount > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Categories")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.museLightGray)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(affirmationCategories, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    var categories = notificationService.affirmationCategories
                                    if categories.contains(category) {
                                        categories.remove(category)
                                    } else {
                                        categories.insert(category)
                                    }
                                    notificationService.updateAffirmationSettings(
                                        count: notificationService.affirmationNotificationCount,
                                        categories: categories
                                    )
                                }
                            }) {
                                Text(category.capitalized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(notificationService.affirmationCategories.contains(category) ? .museSoftWhite : .museLightGray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(notificationService.affirmationCategories.contains(category) ? Color.purple.opacity(0.5) : Color.white.opacity(0.08))
                                    )
                            }
                        }
                    }
                    
                    if notificationService.affirmationCategories.isEmpty {
                        Text("Select at least one category")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
    }
    
    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.museAccentBlue)
                Text("Quote Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.museSoftWhite)
            }
            
            // Frequency Selection (None, 1-5)
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily frequency")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.museLightGray)
                
                HStack(spacing: 6) {
                    ForEach(0...5, id: \.self) { count in
                        Button(action: {
                            notificationService.updateQuoteSettings(
                                count: count,
                                categories: notificationService.quoteCategories
                            )
                        }) {
                            Text(count == 0 ? "None" : "\(count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(notificationService.quoteNotificationCount == count ? .museSoftWhite : .museLightGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(notificationService.quoteNotificationCount == count ? Color.museAccentBlue : Color.white.opacity(0.08))
                                )
                        }
                    }
                }
            }
            
            // Category Selection (only show if frequency > 0)
            if notificationService.quoteNotificationCount > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Categories")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.museLightGray)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(quoteCategories, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    var categories = notificationService.quoteCategories
                                    if categories.contains(category) {
                                        categories.remove(category)
                                    } else {
                                        categories.insert(category)
                                    }
                                    notificationService.updateQuoteSettings(
                                        count: notificationService.quoteNotificationCount,
                                        categories: categories
                                    )
                                }
                            }) {
                                Text(category.capitalized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(notificationService.quoteCategories.contains(category) ? .museSoftWhite : .museLightGray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(notificationService.quoteCategories.contains(category) ? Color.museAccentBlue.opacity(0.5) : Color.white.opacity(0.08))
                                    )
                            }
                        }
                    }
                    
                    if notificationService.quoteCategories.isEmpty {
                        Text("Select at least one category")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
    }
    
    private var authorizationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 36))
                .foregroundColor(.museOrange)
            
            Text("Notifications Disabled")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.museSoftWhite)
            
            Text("Enable notifications to receive daily session reminders.")
                .font(.system(size: 14))
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                notificationService.requestAuthorization { _ in }
            }) {
                Text("Enable Notifications")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.museAccentBlue)
                    .cornerRadius(20)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
    }
    
    private var sessionTypeTabs: some View {
        HStack(spacing: 8) {
            ForEach(NotificationService.SessionType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) { selectedSessionType = type }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: type.icon)
                            .font(.system(size: 20))
                        Text(type.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedSessionType == type ? .museSoftWhite : .museLightGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedSessionType == type ? colorForType(type).opacity(0.3) : Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedSessionType == type ? colorForType(type) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(selectedSessionType.rawValue) Reminders")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.museSoftWhite)
                Spacer()
                Text("\(notificationService.reminders(for: selectedSessionType).count)/\(NotificationService.maxReminders)")
                    .font(.system(size: 12))
                    .foregroundColor(.museLightGray)
            }
            
            let reminders = notificationService.reminders(for: selectedSessionType)
            
            if reminders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 32))
                        .foregroundColor(.museMediumGray)
                    Text("No reminders set")
                        .font(.system(size: 14))
                        .foregroundColor(.museLightGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
            } else {
                ForEach(reminders) { reminder in
                    reminderRow(reminder)
                }
            }
            
            if notificationService.canAddReminder(for: selectedSessionType) {
                Button(action: {
                    newReminderTime = defaultTimeForType(selectedSessionType)
                    showAddReminder = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Reminder")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(colorForType(selectedSessionType))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorForType(selectedSessionType).opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
            }
        }
    }
    
    private func reminderRow(_ reminder: NotificationService.SessionReminder) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(reminder.isEnabled ? .museSoftWhite : .museMediumGray)
                Text("Daily")
                    .font(.system(size: 12))
                    .foregroundColor(.museLightGray)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { _ in notificationService.toggleReminder(reminder) }
            ))
            .tint(colorForType(selectedSessionType))
            
            Button(action: {
                withAnimation { notificationService.removeReminder(reminder) }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
    }
    
    private var addReminderSheet: some View {
        ZStack {
            Color.museDeepNavy.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button("Cancel") { showAddReminder = false }
                        .foregroundColor(.museLightGray)
                    Spacer()
                    Text("Add Reminder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.museSoftWhite)
                    Spacer()
                    Button("Add") {
                        notificationService.addReminder(for: selectedSessionType, at: newReminderTime)
                        showAddReminder = false
                    }
                    .foregroundColor(colorForType(selectedSessionType))
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                HStack(spacing: 12) {
                    Image(systemName: selectedSessionType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(colorForType(selectedSessionType))
                    Text(selectedSessionType.rawValue)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.museSoftWhite)
                }
                
                DatePicker("", selection: $newReminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                
                VStack(spacing: 8) {
                    Text("Notification Preview")
                        .font(.system(size: 12))
                        .foregroundColor(.museLightGray)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.museAccentBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Muse")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.museSoftWhite)
                            Text("It's time for \(selectedSessionType.rawValue.lowercased()).")
                                .font(.system(size: 13))
                                .foregroundColor(.museLightGray)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .presentationDetents([.medium])
    }
    
    private func colorForType(_ type: NotificationService.SessionType) -> Color {
        switch type {
        case .affirmations: return .purple
        case .breathwork: return .museAccentBlue
        case .journaling: return .museOrange
        }
    }
    
    private func defaultTimeForType(_ type: NotificationService.SessionType) -> Date {
        let calendar = Calendar.current
        switch type {
        case .affirmations: return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        case .breathwork: return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
        case .journaling: return calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
}

// MARK: - Flow Layout for Category Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    var body: some View {
        ZStack {
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.museSoftWhite)
                    
                    Text("Last Updated: December 26, 2024")
                        .font(.system(size: 14))
                        .foregroundColor(.museLightGray)
                    
                    Group {
                        policySection(title: "1. Introduction", content: """
Welcome to Muse ("the App"), operated by **Ephesian 28 LLC** ("Company", "we", "us", or "our"). We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our app.

By using the App, you agree to the collection and use of information in accordance with this policy.
""")
                        
                        policySection(title: "2. Information We Collect", content: """
**Data Stored Locally on Your Device:**
• Affirmation preferences and favorites
• Breathwork session history
• Journal entries and mood logs
• App settings and preferences
• Session progress and streaks
• Custom habits and goals

**Data Processed Through Third-Party Services:**
• AI chat conversations (processed via OpenRouter/Google Gemini)
• Text-to-speech requests (processed via OpenAI)

We do NOT collect, store, or have access to your personal data on our servers. All your personal content remains on your device.
""")
                        
                        policySection(title: "3. How We Use Your Information", content: """
Your data is used solely to:
• Provide personalized affirmations and quotes
• Track your wellness journey and progress
• Enable AI-powered coaching conversations
• Deliver notification reminders you configure
• Improve your overall app experience

We do not sell, rent, or share your personal information with third parties for marketing purposes.
""")
                        
                        policySection(title: "4. Third-Party Services", content: """
Muse integrates with the following third-party services:

**OpenRouter (AI Chat):** When you use the AI chat feature, your messages are sent to OpenRouter's API which routes to Google Gemini. These conversations may be processed according to their privacy policies.

**OpenAI (Text-to-Speech):** When you use voice features, text is sent to OpenAI for speech synthesis.

We recommend reviewing the privacy policies of these services:
• OpenRouter: openrouter.ai/privacy
• OpenAI: openai.com/privacy
• Google: policies.google.com/privacy
""")
                        
                        policySection(title: "5. Data Security", content: """
We implement appropriate security measures to protect your information:
• All data is stored locally on your device using iOS secure storage
• API communications use HTTPS encryption
• No personal data is stored on external servers

However, no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to protect your information, we cannot guarantee its absolute security.
""")
                        
                        policySection(title: "6. Your Rights", content: """
You have the right to:
• Access all data stored in the app
• Delete your data at any time by uninstalling the app
• Disable notifications in your device settings
• Opt out of AI features by not using the chat function

All your data can be removed simply by deleting the Muse app from your device.
""")
                        
                        policySection(title: "7. Children's Privacy", content: """
Muse is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.
""")
                        
                        policySection(title: "8. Changes to This Policy", content: """
We may update this privacy policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy. You are advised to review this Privacy Policy periodically for any changes.
""")
                        
                        policySection(title: "9. Contact Us", content: """
If you have questions about this Privacy Policy, please contact us at:

**Ephesian 28 LLC**
Email: ephesian28mgmt@yahoo.com
""")
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.museSoftWhite)
            
            Text(LocalizedStringKey(content))
                .font(.system(size: 15))
                .foregroundColor(.museLightGray)
                .lineSpacing(4)
        }
        .padding(.top, 8)
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    var body: some View {
        ZStack {
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.museSoftWhite)
                    
                    Text("Last Updated: December 26, 2024")
                        .font(.system(size: 14))
                        .foregroundColor(.museLightGray)
                    
                    Group {
                        policySection(title: "1. Agreement to Terms", content: """
By downloading, installing, or using Muse ("the App"), provided by **Ephesian 28 LLC** ("Company", "we", "us"), you agree to be strictly bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you must immediately uninstall and discontinue use of the App.

**THESE TERMS INCLUDE A BINDING ARBITRATION CLAUSE AND A CLASS ACTION WAIVER.**
""")
                        
                        policySection(title: "2. Description of Service", content: """
Muse is a wellness and mindfulness application that provides:
• Daily affirmations and inspirational quotes
• Guided breathwork exercises
• Journaling and mood tracking features
• AI-powered coaching conversations
• Meditation and relaxation tools

The App is designed solely for informational, educational, and entertainment purposes.
""")
                        
                        policySection(title: "3. Health and Medical Disclaimer", content: """
**STRICT MEDICAL DISCLAIMER: THE APP IS NOT A MEDICAL DEVICE AND DOES NOT PROVIDE MEDICAL ADVICE.**

(a) **No Medical Advice:** The content, tools, and AI interactions within the App are not intended to diagnose, treat, cure, or prevent any disease, mental health condition, or physical ailment.
(b) **Consult a Professional:** Always seek the advice of your physician or qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay in seeking it because of something you have read on the App.
(c) **Use at Your Own Risk:** Your use of any information or tools provided by the App is solely at your own risk. Ephesian 28 LLC is not responsible for any health problems that may result from training programs, consultations, products, or events you learn about through the App.
(d) **Emergency:** If you think you may have a medical emergency, call your doctor or 911 immediately.
""")
                        
                        policySection(title: "4. User Conduct & Prohibited Use", content: """
You agree to use the App only for lawful purposes. You are strictly prohibited from:
• Using the App for any illegal purpose.
• Harassing, threatening, or defrauding other users or the Company.
• Meaningfully attempting to bypass any security features.
• Reverse engineering, decompiling, or disassembling the App.
• Using the AI chat to generate hate speech, violence, or illegal content.

Ephesian 28 LLC reserves the right to terminate your access immediately, without notice, for any violation of these Terms.
""")
                        
                        policySection(title: "5. Intellectual Property Rights", content: """
The App and its entire contents, features, and functionality (including but not limited to all information, software, text, displays, images, video, and audio) are owned by **Ephesian 28 LLC**, its licensors, or other providers of such material and are protected by United States and international copyright, trademark, patent, trade secret, and other intellectual property or proprietary rights laws.
""")
                        
                        policySection(title: "6. AI-Generated Content Disclaimer", content: """
The App utilizes artificial intelligence ("AI") to generate certain content. You acknowledge that:
• AI responses may be inaccurate, inappropriate, or misleading.
• You should not rely on AI for advice of any kind (medical, legal, financial, etc.).
• Ephesian 28 LLC expressly disclaims all liability for any actions you take based on AI-generated content.
""")
                        
                        policySection(title: "7. Limitation of Liability", content: """
**TO THE MAXIMUM EXTENT PERMITTED BY LAW:**

(A) IN NO EVENT SHALL **EPHESIAN 28 LLC**, ITS OFFICERS, DIRECTORS, EMPLOYEES, OR AGENTS, BE LIABLE TO YOU FOR ANY INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES WHATSOEVER RESULTING FROM ANY (I) ERRORS, MISTAKES, OR INACCURACIES OF CONTENT, (II) PERSONAL INJURY OR PROPERTY DAMAGE, OF ANY NATURE WHATSOEVER, RESULTING FROM YOUR ACCESS TO AND USE OF OUR APP, (III) ANY UNAUTHORIZED ACCESS TO OR USE OF OUR SECURE SERVERS AND/OR ANY AND ALL PERSONAL INFORMATION STORED THEREIN.

(B) IN NO EVENT SHALL THE TOTAL LIABILITY OF EPHESIAN 28 LLC EXCEED THE AMOUNT PAID BY YOU, IF ANY, FOR ACCESSING THE APP.
""")
                        
                        policySection(title: "8. Indemnification", content: """
You agree to defend, indemnify, and hold harmless **Ephesian 28 LLC** and its officers, directors, employees, and agents from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney's fees) arising from: (i) your use of and access to the App; (ii) your violation of any term of these Terms; (iii) your violation of any third-party right, including without limitation any copyright, property, or privacy right. This defense and indemnification obligation will survive these Terms and your use of the App.
""")
                        
                        policySection(title: "9. Dispute Resolution: Arbitration & Class Action Waiver", content: """
**PLEASE READ THIS SECTION CAREFULLY. IT AFFECTS YOUR LEGAL RIGHTS.**

(a) **Binding Arbitration:** Any dispute, controversy, or claim arising out of or relating to these Terms or the App shall be settled by binding arbitration in accordance with the American Arbitration Association (AAA) rules. Judgment on the award rendered by the arbitrator(s) may be entered in any court having jurisdiction thereof.

(b) **Class Action Waiver:** YOU AND EPHESIAN 28 LLC AGREE THAT EACH MAY BRING CLAIMS AGAINST THE OTHER ONLY IN YOUR OR ITS INDIVIDUAL CAPACITY AND NOT AS A PLAINTIFF OR CLASS MEMBER IN ANY PURPORTED CLASS OR REPRESENTATIVE PROCEEDING.

(c) **Jury Trial Waiver:** You and Ephesian 28 LLC hereby waive any constitutional and statutory rights to sue in court and have a trial in front of a judge or a jury.
""")
                        
                        policySection(title: "10. Contact Information", content: """
For any questions regarding these Terms, please contact:

**Ephesian 28 LLC**
Email: ephesian28mgmt@yahoo.com
""")
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.museSoftWhite)
            
            Text(LocalizedStringKey(content))
                .font(.system(size: 15))
                .foregroundColor(.museLightGray)
                .lineSpacing(4)
        }
        .padding(.top, 8)
    }
}

// MARK: - EULA View
struct EULAView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    var body: some View {
        ZStack {
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("End User License Agreement")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.museSoftWhite)
                    
                    Text("Last Updated: December 26, 2024")
                        .font(.system(size: 14))
                        .foregroundColor(.museLightGray)
                    
                    Group {
                        policySection(title: "1. Acknowledgment", content: """
This End User License Agreement ("EULA") is a legal agreement between you ("User") and **Ephesian 28 LLC** ("Licensor") for the use of the Muse mobile application ("Application").

You acknowledge that this EULA is concluded between you and Ephesian 28 LLC only, and not with Apple. Ephesian 28 LLC, not Apple, is solely responsible for the Application and the content thereof.
""")
                        
                        policySection(title: "2. License Grant", content: """
The Licensor grants you a revocable, non-exclusive, non-transferable, limited license to download, install, and use the Application for your personal, non-commercial purposes strictly in accordance with the terms of this EULA and the Usage Rules set forth in the Apple Media Services Terms and Conditions.
""")
                        
                        policySection(title: "3. Scope of License", content: """
You may not:
• Distribute or make the Application available over a network where it could be used by multiple devices at the same time.
• Rent, lease, lend, sell, redistribute, or sublicense the Application.
• Reverse engineer, disassemble, attempt to derive the source code of, or modify the Application.
• Create derivative works of the Application.

Any attempt to do so is a violation of the rights of Ephesian 28 LLC and its licensors.
""")
                        
                        policySection(title: "4. No Warranty", content: """
**YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT USE OF THE APPLICATION IS AT YOUR SOLE RISK.** TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE APPLICATION IS PROVIDED "AS IS" AND "AS AVAILABLE," WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND.

EPHESIAN 28 LLC HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS WITH RESPECT TO THE APPLICATION, EITHER EXPRESS, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, OF SATISFACTORY QUALITY, OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY, AND OF NON-INFRINGEMENT OF THIRD-PARTY RIGHTS.
""")
                        
                        policySection(title: "5. Limitation of Liability", content: """
TO THE EXTENT NOT PROHIBITED BY LAW, IN NO EVENT SHALL **EPHESIAN 28 LLC** BE LIABLE FOR PERSONAL INJURY OR ANY INCIDENTAL, SPECIAL, INDIRECT, OR CONSEQUENTIAL DAMAGES WHATSOEVER, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, LOSS OF DATA, BUSINESS INTERRUPTION, OR ANY OTHER COMMERCIAL DAMAGES OR LOSSES, ARISING OUT OF OR RELATED TO YOUR USE OF OR INABILITY TO USE THE APPLICATION, HOWEVER CAUSED, REGARDLESS OF THE THEORY OF LIABILITY (CONTRACT, TORT, OR OTHERWISE).
""")
                        
                        policySection(title: "6. Maintenance and Support", content: """
Ephesian 28 LLC is solely responsible for providing any maintenance and support services with respect to the Application. You acknowledge that Apple has no obligation whatsoever to furnish any maintenance and support services with respect to the Application.
""")
                        
                        policySection(title: "7. Third-Party Beneficiary", content: """
You acknowledge and agree that Apple, and Apple's subsidiaries, are third-party beneficiaries of this EULA, and that, upon your acceptance of the terms and conditions of this EULA, Apple will have the right (and will be deemed to have accepted the right) to enforce this EULA against you as a third-party beneficiary thereof.
""")
                        
                        policySection(title: "8. Dispute Resolution", content: """
Any dispute arising under this EULA will be resolved through binding arbitration as detailed in the Terms of Service. **YOU WAIVE YOUR RIGHT TO A JURY TRIAL AND TO PARTICIPATE IN A CLASS ACTION LAWSUIT.**
""")
                        
                        policySection(title: "9. Governing Law", content: """
The laws of the State of Delaware, excluding its conflicts of law rules, govern this license and your use of the Application. Your use of the Application may also be subject to other local, state, national, or international laws.
""")
                        
                        policySection(title: "10. Contact Information", content: """
Should you have any questions, complaints, or claims with respect to the Application, please contact:

**Ephesian 28 LLC**
Email: ephesian28mgmt@yahoo.com
""")
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.museSoftWhite)
            
            Text(LocalizedStringKey(content))
                .font(.system(size: 15))
                .foregroundColor(.museLightGray)
                .lineSpacing(4)
        }
        .padding(.top, 8)
    }
}
