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
                            Button(action: {}) {
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
                            longestStreak: progressService.longestStreak
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
    let longestStreak: Int
    
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
                value: "\(longestStreak)",
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
