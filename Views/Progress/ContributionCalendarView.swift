
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
