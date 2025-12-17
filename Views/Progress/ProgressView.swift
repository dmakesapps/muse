import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressService = ProgressService()
    
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    var body: some View {
        NavigationStack {
            ZStack {

                // Background
                MuseBackgroundView(selectedBackground: selectedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            
                            Text("Progress")
                                .font(.museDisplayLarge())
                                .foregroundColor(.museSoftWhite)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Streak Counter
                        StreakCounterView(streak: progressService.currentStreak)
                            .padding(.horizontal, 20)
                        
                        // Key Metrics
                        KeyMetricsView(
                            totalSessions: progressService.totalSessions,
                            totalTime: progressService.totalTime,
                            longestStreak: progressService.longestStreak
                        )
                        .padding(.horizontal, 20)
                        
                        // Charts Section
                        VStack(spacing: 20) {
                            // Sessions by Day of Week
                            SessionsByDayChart(progressService: progressService)
                                .padding(.horizontal, 20)
                            
                            // Contribution Calendar
                            ContributionCalendarView(progressService: progressService)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
            .onAppear {
                progressService.setModelContext(modelContext)
            }
        }
    }
}

// MARK: - Streak Counter View
struct StreakCounterView: View {
    let streak: Int
    @State private var animatedStreak: Int = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                    .symbolEffect(.bounce, value: animatedStreak)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(animatedStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.museSoftWhite)
                        .contentTransition(.numericText())
                    
                    Text("Day Streak")
                        .font(.museBodyMedium())
                        .foregroundColor(.museLightGray)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.museDarkGray.opacity(0.6))
                    .rainbowBorder()
            )

        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedStreak = streak
            }
        }
        .onChange(of: streak) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedStreak = newValue
            }
        }
    }
}

// MARK: - Key Metrics View
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
                title: "Total Sessions",
                value: "\(totalSessions)",
                icon: "checkmark.circle.fill",
                color: .museAccentBlue
            )
            
            MetricCard(
                title: "Time Spent",
                value: formattedTime,
                icon: "clock.fill",
                color: .museTeal
            )
            
            MetricCard(
                title: "Longest Streak",
                value: "\(longestStreak)",
                icon: "star.fill",
                color: .musePremiumGold
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
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.museSoftWhite)
            
            Text(title)
                .font(.museCaption())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.museDarkGray.opacity(0.6))
                .rainbowBorder()
        )
    }
}



// MARK: - Sessions By Day Chart
struct SessionsByDayChart: View {
    let progressService: ProgressService
    
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions by Day of Week")
                .font(.museHeadline())
                .foregroundColor(.museSoftWhite)
            
            let dayCounts = progressService.getSessionsByDayOfWeek()
            
            if dayCounts.isEmpty {
                EmptyChartView(message: "Complete sessions to see your weekly pattern")
            } else {
                Chart {
                    ForEach(1...7, id: \.self) { weekday in
                        BarMark(
                            x: .value("Day", dayNames[weekday - 1]),
                            y: .value("Sessions", dayCounts[weekday] ?? 0)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.museAccentBlue, Color.museTeal],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(Color.museLightGray)
                            .font(.system(size: 10, design: .rounded))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.museMediumGray.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(Color.museLightGray)
                            .font(.system(size: 10, design: .rounded))
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
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.museMediumGray)
            
            Text(message)
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.museDarkGray.opacity(0.6))
                .rainbowBorder()
        )
    }
}

// MARK: - Contribution Calendar View
struct ContributionCalendarView: View {
    let progressService: ProgressService
    
    @State private var offset: Int = 0 // Months offset from current
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var currentMonthDate: Date {
        calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate) else { return [] }
        
        let range = calendar.range(of: .day, in: .month, for: currentMonthDate)!
        let numDays = range.count
        
        return (0..<numDays).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monthInterval.start)
        }
    }
    
    private var startOffset: Int {
        guard let monthStart = calendar.dateInterval(of: .month, for: currentMonthDate)?.start else { return 0 }
        let weekday = calendar.component(.weekday, from: monthStart)
        return weekday - 1 // 1-based (Sunday=1) to 0-based index
    }
    
    private func getSessionCount(for date: Date) -> Int {
        let sessions = progressService.getAllSessions()
        return sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }
    
    private func getIntensityColor(count: Int) -> Color {
        if count == 0 {
            return Color.museMediumGray.opacity(0.3)
        } else if count == 1 {
            return Color.museAccentBlue.opacity(0.4)
        } else if count == 2 {
            return Color.museAccentBlue.opacity(0.7)
        } else {
            return Color.museAccentBlue // Max intensity
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Calendar")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { withAnimation { offset -= 1 } }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.museLightGray)
                    }
                    
                    Text(currentMonthDate.formatted(.dateTime.month().year()))
                        .font(.museBodyMedium())
                        .foregroundColor(.museSoftWhite)
                        .frame(minWidth: 100)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { withAnimation { offset += 1 } }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(offset >= 0 ? .museMediumGray.opacity(0.3) : .museLightGray)
                    }
                    .disabled(offset >= 0)
                }
            }
            
            VStack(spacing: 12) {
                // Day Headers
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.museMediumGray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 8) {
                    // Empty spaces for start of month
                    ForEach(0..<startOffset, id: \.self) { _ in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                    
                    // Days
                    ForEach(daysInMonth, id: \.self) { date in
                        let count = getSessionCount(for: date)
                        let isToday = calendar.isDateInToday(date)
                        
                        ZStack {
                            Circle()
                                .fill(getIntensityColor(count: count))
                            
                            if isToday {
                                Circle()
                                    .stroke(Color.museSoftWhite, lineWidth: 1)
                            }
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 10))
                                .foregroundColor(count > 0 ? .white : .museLightGray)
                        }
                        .aspectRatio(1, contentMode: .fit)
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
