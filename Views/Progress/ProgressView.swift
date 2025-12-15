import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressService = ProgressService()
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                if let uiImage = UIImage(named: "backgroundjungle2") {
                    GeometryReader { geometry in
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .blur(radius: 30)
                            .overlay(Color.black.opacity(0.3))
                    }
                    .ignoresSafeArea()
                } else {
                    Color.museDeepNavy
                        .ignoresSafeArea()
                }
                
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
                            // Time Range Selector
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 20)
                            
                            // Sessions Over Time Chart
                            SessionsOverTimeChart(
                                progressService: progressService,
                                days: selectedTimeRange == .week ? 7 : 30
                            )
                            .padding(.horizontal, 20)
                            
                            // Sessions by Day of Week
                            SessionsByDayChart(progressService: progressService)
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

// MARK: - Sessions Over Time Chart
struct SessionsOverTimeChart: View {
    let progressService: ProgressService
    let days: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions Over Time")
                .font(.museHeadline())
                .foregroundColor(.museSoftWhite)
            
            let data = progressService.getSessionsForLastDays(days)
            
            if data.isEmpty {
                EmptyChartView(message: "No sessions yet. Start your first affirmation session!")
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        BarMark(
                            x: .value("Day", index),
                            y: .value("Sessions", item.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.museGradientStart, Color.museGradientEnd],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.museMediumGray.opacity(0.3))
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

#Preview {
    ProgressView()
        .modelContainer(for: [AffirmationSession.self])
}
