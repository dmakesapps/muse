import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Query(sort: \Promise.createdAt, order: .reverse) private var promises: [Promise]
    @Binding var isDarkMode: Bool
    @State private var selectedDate = Date()
    
    init(isDarkMode: Binding<Bool> = .constant(false)) {
        self._isDarkMode = isDarkMode
    }
    
    var body: some View {
        ZStack {
            // Background - matching PromiseListView
            (isDarkMode 
                ? LinearGradient(
                    colors: [Color(white: 0.1), Color(white: 0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                : LinearGradient(
                    colors: [Color.white, Color(white: 0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Contribution Heatmap Calendar
                    ContributionHeatmap(
                        promises: promises,
                        isDarkMode: isDarkMode,
                        selectedDate: $selectedDate
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    // Schedule Card
                    ScheduleCard(
                        date: formattedDate,
                        promises: promisesForSelectedDate,
                        isDarkMode: isDarkMode
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Schedule")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isDarkMode.toggle()
                } label: {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.themeAccent)
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var promisesForSelectedDate: [PromiseScheduleItem] {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let now = Date()
        
        return promises.compactMap { promise -> PromiseScheduleItem? in
            var notificationTimesForDay: [Date] = []
            
            // Check for daily notifications
            if !promise.customDailyTimes.isEmpty {
                for time in promise.customDailyTimes {
                    let (hour, minute) = DateUtils.timeComponents(from: time)
                    if let notificationDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDay) {
                        if calendar.isDate(notificationDate, inSameDayAs: selectedDate) {
                            notificationTimesForDay.append(notificationDate)
                        }
                    }
                }
            }
            
            // Check for weekly notifications
            if !promise.customWeeklyTimes.isEmpty && !promise.customWeeklyDays.isEmpty {
                let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                if promise.customWeeklyDays.contains(selectedWeekday) {
                    for time in promise.customWeeklyTimes {
                        let (hour, minute) = DateUtils.timeComponents(from: time)
                        if let notificationDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDay) {
                            notificationTimesForDay.append(notificationDate)
                        }
                    }
                }
            }
            
            // Check for monthly notifications
            if !promise.customMonthlyTimes.isEmpty, let monthlyDay = promise.customMonthlyDay {
                let selectedDayOfMonth = calendar.component(.day, from: selectedDate)
                if selectedDayOfMonth == monthlyDay {
                    for time in promise.customMonthlyTimes {
                        let (hour, minute) = DateUtils.timeComponents(from: time)
                        if let notificationDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDay) {
                            notificationTimesForDay.append(notificationDate)
                        }
                    }
                }
            }
            
            // If no notifications for this day, return nil
            guard !notificationTimesForDay.isEmpty else {
                return nil
            }
            
            // Count completed instances for this day
            var completedCount = 0
            for notificationTime in notificationTimesForDay {
                if promise.isNotificationInstanceCompleted(for: notificationTime) {
                    completedCount += 1
                }
            }
            
            // Calculate completion percentage for this day
            let dayCompletionPercentage = notificationTimesForDay.count > 0 
                ? Int((Double(completedCount) / Double(notificationTimesForDay.count)) * 100)
                : 0
            
            // Find the next closest notification time (or first upcoming, or most recent past)
            let sortedTimes = notificationTimesForDay.sorted()
            let nextTime: Date = sortedTimes.first { $0 > now } ?? sortedTimes.last ?? sortedTimes.first!
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let timeString = timeFormatter.string(from: nextTime)
            
            // Determine status based on if the next time has passed
            let status: PromiseScheduleItem.PromiseEventStatus = nextTime < now ? .completed : .upcoming
            
            return PromiseScheduleItem(
                promise: promise,
                time: timeString,
                status: status,
                dayCompletionPercentage: dayCompletionPercentage
            )
        }
        .sorted { item1, item2 in
            // Sort by time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            if let time1 = formatter.date(from: item1.time),
               let time2 = formatter.date(from: item2.time) {
                return time1 < time2
            }
            return false
        }
    }
}

// MARK: - Promise Schedule Item
struct PromiseScheduleItem: Identifiable {
    let id: UUID
    let promise: Promise
    let time: String
    let status: PromiseEventStatus
    let dayCompletionPercentage: Int // Completion percentage for this specific day
    
    init(promise: Promise, time: String, status: PromiseEventStatus, dayCompletionPercentage: Int = 0) {
        self.id = promise.id
        self.promise = promise
        self.time = time
        self.status = status
        self.dayCompletionPercentage = dayCompletionPercentage
    }
    
    enum PromiseEventStatus {
        case upcoming
        case inProgress
        case completed
    }
}

// MARK: - Schedule Card Component (Card-07 converted to SwiftUI)
struct ScheduleCard: View {
    let date: String
    let promises: [PromiseScheduleItem]
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Calendar Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isDarkMode
                                ? Color(white: 0.2)
                                : Color(white: 0.95)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(
                            isDarkMode
                                ? Color.white.opacity(0.7)
                                : Color.black.opacity(0.6)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    Text(date)
                        .font(.system(size: 14))
                        .foregroundColor(
                            isDarkMode
                                ? Color.white.opacity(0.6)
                                : Color.black.opacity(0.6)
                        )
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(
                        isDarkMode
                            ? Color(white: 0.15).opacity(0.8)
                            : Color.white.opacity(0.8)
                    )
            )
            
            // Promises List
            VStack(spacing: 0) {
                if promises.isEmpty {
                    VStack(spacing: 8) {
                        Text("No promises scheduled")
                            .font(.system(size: 14))
                            .foregroundColor(
                                isDarkMode
                                    ? Color.white.opacity(0.5)
                                    : Color.black.opacity(0.5)
                            )
                        Text("for this day")
                            .font(.system(size: 13))
                            .foregroundColor(
                                isDarkMode
                                    ? Color.white.opacity(0.4)
                                    : Color.black.opacity(0.4)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(Array(promises.enumerated()), id: \.element.id) { index, promiseItem in
                        PromiseScheduleRow(
                            promiseItem: promiseItem,
                            isDarkMode: isDarkMode
                        )
                        
                        if index < promises.count - 1 {
                            Divider()
                                .background(
                                    isDarkMode
                                        ? Color.white.opacity(0.1)
                                        : Color.black.opacity(0.1)
                                )
                        }
                    }
                }
            }
            .background(
                Rectangle()
                    .fill(
                        isDarkMode
                            ? Color(white: 0.15).opacity(0.8)
                            : Color.white.opacity(0.8)
                    )
            )
            
            // Footer
            Button {
                // Handle "View Full Schedule" action
            } label: {
                HStack(spacing: 8) {
                    Text("View Full Schedule")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isDarkMode
                                ? Color(white: 0.2)
                                : Color(white: 0.95)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(20)
            .background(
                Rectangle()
                    .fill(
                        isDarkMode
                            ? Color(white: 0.15).opacity(0.8)
                            : Color.white.opacity(0.8)
                    )
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    isDarkMode
                        ? Color(white: 0.15).opacity(0.8)
                        : Color.white.opacity(0.8)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    isDarkMode
                        ? Color(white: 0.2).opacity(0.5)
                        : Color(white: 0.3).opacity(0.3),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - Promise Schedule Row
struct PromiseScheduleRow: View {
    let promiseItem: PromiseScheduleItem
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(promiseItem.promise.text)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .black)
                    .lineLimit(2)
                
                Spacer()
                
                // Status Dot
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 6, height: 6)
            }
            
            HStack(spacing: 16) {
                // Time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(
                            isDarkMode
                                ? Color.white.opacity(0.6)
                                : Color.black.opacity(0.6)
                        )
                    
                    Text(promiseItem.time)
                        .font(.system(size: 13))
                        .foregroundColor(
                            isDarkMode
                                ? Color.white.opacity(0.6)
                                : Color.black.opacity(0.6)
                        )
                }
                
                // Day Completion Percentage
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(
                            isDarkMode
                                ? Color.white.opacity(0.6)
                                : Color.black.opacity(0.6)
                        )
                    
                    Text("\(promiseItem.dayCompletionPercentage)%")
                        .font(.system(size: 13))
                        .foregroundColor(
                            isDarkMode
                                ? Color.white.opacity(0.6)
                                : Color.black.opacity(0.6)
                        )
                }
            }
        }
        .padding(20)
    }
    
    private var statusDotColor: Color {
        switch promiseItem.status {
        case .completed:
            return isDarkMode
                ? Color.white.opacity(0.4)
                : Color.black.opacity(0.3)
        case .inProgress:
            return Color.themeAccent
        case .upcoming:
            return isDarkMode
                ? Color.white.opacity(0.2)
                : Color.black.opacity(0.2)
        }
    }
}

// MARK: - Contribution Heatmap Calendar
struct ContributionHeatmap: View {
    let promises: [Promise]
    let isDarkMode: Bool
    @Binding var selectedDate: Date
    
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    
    // Generate activity data for the last year
    private var activityData: [Date: Int] {
        var activity: [Date: Int] = [:]
        let today = calendar.startOfDay(for: Date())
        
        // Count completions per day from completed notification instances
        for promise in promises {
            // Use completedNotificationInstances for more accurate tracking
            for completedInstance in promise.completedNotificationInstances {
                let day = calendar.startOfDay(for: completedInstance)
                activity[day, default: 0] += 1
            }
        }
        
        return activity
    }
    
    private var maxActivity: Int {
        activityData.values.max() ?? 1
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func previousMonth() {
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = prevMonth
        }
    }
    
    private func nextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            // Don't allow going beyond current month
            let today = Date()
            if nextMonth <= calendar.date(byAdding: .month, value: 1, to: today) ?? today {
                currentMonth = nextMonth
            }
        }
    }
    
    private var canGoNext: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        let today = Date()
        return nextMonth <= calendar.date(byAdding: .month, value: 1, to: today) ?? today
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and navigation
            HStack {
                Text("Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Spacer()
                
                // Navigation arrows
                HStack(spacing: 8) {
                    Button {
                        previousMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(
                                isDarkMode
                                    ? Color.white.opacity(0.7)
                                    : Color.black.opacity(0.7)
                            )
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(
                                        isDarkMode
                                            ? Color.white.opacity(0.1)
                                            : Color.black.opacity(0.05)
                                    )
                            )
                    }
                    
                    Button {
                        nextMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(
                                canGoNext
                                    ? (isDarkMode
                                        ? Color.white.opacity(0.7)
                                        : Color.black.opacity(0.7))
                                    : (isDarkMode
                                        ? Color.white.opacity(0.3)
                                        : Color.black.opacity(0.3))
                            )
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(
                                        isDarkMode
                                            ? Color.white.opacity(0.1)
                                            : Color.black.opacity(0.05)
                                    )
                            )
                    }
                    .disabled(!canGoNext)
                }
            }
            
            // Month title
            Text(monthTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(
                    isDarkMode
                        ? Color.white.opacity(0.6)
                        : Color.black.opacity(0.6)
                )
            
            // Heatmap Grid
            HeatmapGrid(
                activityData: activityData,
                maxActivity: maxActivity,
                isDarkMode: isDarkMode,
                currentMonth: currentMonth,
                selectedDate: $selectedDate
            )
            
            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 11))
                    .foregroundColor(
                        isDarkMode
                            ? Color.white.opacity(0.5)
                            : Color.black.opacity(0.5)
                    )
                
                HStack(spacing: 3) {
                    ForEach(0..<4) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(activityColor(for: level, maxLevel: 3))
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text("More")
                    .font(.system(size: 11))
                    .foregroundColor(
                        isDarkMode
                            ? Color.white.opacity(0.5)
                            : Color.black.opacity(0.5)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isDarkMode
                        ? Color(white: 0.15).opacity(0.8)
                        : Color.white.opacity(0.8)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isDarkMode
                        ? Color(white: 0.2).opacity(0.5)
                        : Color(white: 0.3).opacity(0.3),
                    lineWidth: 1
                )
        )
    }
    
    private func activityColor(for level: Int, maxLevel: Int) -> Color {
        let intensity = Double(level) / Double(maxLevel)
        
        if isDarkMode {
            // Dark mode: darker green for less, brighter for more
            return Color(red: 0.1 + intensity * 0.3, green: 0.4 + intensity * 0.4, blue: 0.2 + intensity * 0.2)
        } else {
            // Light mode: lighter green for less, darker for more
            return Color(red: 0.9 - intensity * 0.2, green: 0.95 - intensity * 0.15, blue: 0.85 - intensity * 0.15)
        }
    }
}

// MARK: - Heatmap Grid
struct HeatmapGrid: View {
    let activityData: [Date: Int]
    let maxActivity: Int
    let isDarkMode: Bool
    let currentMonth: Date
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let squareSize: CGFloat = 12
    private let spacing: CGFloat = 3
    
    // Generate weeks for the current month only
    private var weeks: [[Date?]] {
        // Get the first and last day of the current month
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth),
              let lastOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: firstOfMonth) else {
            return []
        }
        
        // Find the Sunday of the week containing the first day of the month
        let firstWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstOfMonth)
        guard let startOfFirstWeek = calendar.date(from: firstWeekComponents) else { return [] }
        
        // Find the last day of the week containing the last day of the month
        let lastWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastOfMonth)
        guard let startOfLastWeek = calendar.date(from: lastWeekComponents) else { return [] }
        
        var allWeeks: [[Date?]] = []
        var currentWeekStart = startOfFirstWeek
        let today = calendar.startOfDay(for: Date())
        
        // Generate weeks for the month
        while currentWeekStart <= startOfLastWeek {
            var week: [Date?] = []
            for dayOffset in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                    let dayStart = calendar.startOfDay(for: day)
                    // Only include days that are within the month
                    if dayStart >= calendar.startOfDay(for: firstOfMonth) &&
                       dayStart <= calendar.startOfDay(for: lastOfMonth) {
                        week.append(dayStart)
                    } else {
                        week.append(nil) // Placeholder for days outside the month
                    }
                } else {
                    week.append(nil)
                }
            }
            allWeeks.append(week)
            
            // Move to next week
            if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) {
                currentWeekStart = nextWeek
            } else {
                break
            }
        }
        
        return allWeeks
    }
    
    var body: some View {
        GeometryReader { geometry in
            let dayLabelWidth: CGFloat = 30 // Approximate width for day labels
            let labelSpacing: CGFloat = 4
            let availableWidth = geometry.size.width - dayLabelWidth - labelSpacing
            let weekCount = max(1, CGFloat(weeks.count))
            let totalSpacing = spacing * (weekCount - 1)
            let calculatedSquareSize = max(12, min(14, (availableWidth - totalSpacing) / weekCount))
            
            HStack(alignment: .top, spacing: labelSpacing) {
                // Day labels (Mon, Wed, Fri) - vertical on left
                VStack(alignment: .trailing, spacing: spacing) {
                    Text("")
                        .frame(height: calculatedSquareSize)
                    ForEach([1, 3, 5], id: \.self) { weekday in
                        Text(dayLabel(for: weekday))
                            .font(.system(size: 10))
                            .foregroundColor(
                                isDarkMode
                                    ? Color.white.opacity(0.4)
                                    : Color.black.opacity(0.4)
                            )
                            .frame(height: calculatedSquareSize * 2 + spacing)
                    }
                }
                .padding(.trailing, 4)
                .frame(width: dayLabelWidth, alignment: .trailing)
                
                // Week columns (each week is a column, days stack vertically)
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                        VStack(spacing: spacing) {
                            ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, day in
                            if let day = day {
                                HeatmapSquare(
                                    date: day,
                                    activity: activityData[day] ?? 0,
                                    maxActivity: maxActivity,
                                    squareSize: calculatedSquareSize,
                                    isDarkMode: isDarkMode,
                                    isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                                    onTap: {
                                        selectedDate = day
                                    }
                                )
                                } else {
                                    // Empty square for days outside the month
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.clear)
                                        .frame(width: calculatedSquareSize, height: calculatedSquareSize)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: CGFloat(7 * Int(14 + spacing)) + 16)
    }
    
    private func dayLabel(for weekday: Int) -> String {
        let labels = ["", "Mon", "", "Wed", "", "Fri", ""]
        return labels[weekday]
    }
}

// MARK: - Heatmap Square
struct HeatmapSquare: View {
    let date: Date
    let activity: Int
    let maxActivity: Int
    let squareSize: CGFloat
    let isDarkMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 2)
                .fill(colorForActivity)
                .frame(width: squareSize, height: squareSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(
                            isSelected
                                ? Color.themeAccent
                                : (isDarkMode
                                    ? Color.white.opacity(0.1)
                                    : Color.black.opacity(0.05)),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private var colorForActivity: Color {
        guard maxActivity > 0 else {
            return isDarkMode
                ? Color(white: 0.15)
                : Color(white: 0.95)
        }
        
        let level = min(Int(Double(activity) / Double(maxActivity) * 4), 4)
        
        if activity == 0 {
            return isDarkMode
                ? Color(white: 0.15)
                : Color(white: 0.95)
        }
        
        let intensity = Double(level) / 4.0
        
        if isDarkMode {
            // Dark mode: darker green for less, brighter for more
            return Color(red: 0.1 + intensity * 0.3, green: 0.4 + intensity * 0.4, blue: 0.2 + intensity * 0.2)
        } else {
            // Light mode: lighter green for less, darker for more
            return Color(red: 0.9 - intensity * 0.2, green: 0.95 - intensity * 0.15, blue: 0.85 - intensity * 0.15)
        }
    }
}
