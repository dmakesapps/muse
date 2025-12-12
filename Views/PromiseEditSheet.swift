 import SwiftUI
import SwiftData

// MARK: - Time Picker Row Component
struct TimePickerRow: View {
    let index: Int
    @Binding var time: Date
    let onDelete: (() -> Void)?
    let isDarkMode: Bool
    
    init(index: Int, time: Binding<Date>, onDelete: (() -> Void)?, isDarkMode: Bool = false) {
        self.index = index
        self._time = time
        self.onDelete = onDelete
        self.isDarkMode = isDarkMode
    }
    
    var body: some View {
        HStack {
            DatePicker("Time \(index + 1)", selection: $time, displayedComponents: .hourAndMinute)
                .tint(Color.themeAccent)
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(white: 0.2) : Color(white: 0.9))
        )
    }
}

struct PromiseEditSheet: View {
    @Bindable var promise: Promise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var agents: [NotificationAgent]
    @Query private var profiles: [UserProfile]
    @Binding var isDarkMode: Bool
    
    @State private var showDeleteConfirmation = false
    
    // Custom frequency state (this is now the only way to set frequencies)
    @State private var customDailyTimes: [Date]
    @State private var customWeeklyDays: [Int]
    @State private var customWeeklyTimes: [Date]
    @State private var customMonthlyDay: Int?
    @State private var customMonthlyTimes: [Date]
    @State private var customMonthlyReminderCount: Int
    @State private var customFrequencyType: CustomFrequencyType = .daily
    
    // Duration state
    @State private var hasDuration: Bool
    @State private var durationValue: Int
    @State private var durationUnit: DurationUnit = .days
    
    enum DurationUnit: String, CaseIterable {
        case days = "Days"
        case weeks = "Weeks"
        case months = "Months"
        case years = "Years"
        
        var daysMultiplier: Int {
            switch self {
            case .days: return 1
            case .weeks: return 7
            case .months: return 30
            case .years: return 365
            }
        }
    }
    
    enum CustomFrequencyType: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    init(promise: Promise, isDarkMode: Binding<Bool> = .constant(false)) {
        self.promise = promise
        self._isDarkMode = isDarkMode
        let defaultTime = DateUtils.defaultTime()
        
        _customDailyTimes = State(initialValue: promise.customDailyTimes.isEmpty ? [defaultTime] : promise.customDailyTimes)
        _customWeeklyDays = State(initialValue: promise.customWeeklyDays)
        _customWeeklyTimes = State(initialValue: promise.customWeeklyTimes.isEmpty ? [defaultTime] : promise.customWeeklyTimes)
        _customMonthlyDay = State(initialValue: promise.customMonthlyDay ?? 1)
        _customMonthlyTimes = State(initialValue: promise.customMonthlyTimes.isEmpty ? [defaultTime] : promise.customMonthlyTimes)
        _customMonthlyReminderCount = State(initialValue: promise.customMonthlyReminderCount)
        
        // Determine which type to show based on what's populated
        // Priority: Weekly > Monthly > Daily
        if !promise.customWeeklyDays.isEmpty && !promise.customWeeklyTimes.isEmpty {
            _customFrequencyType = State(initialValue: .weekly)
        } else if promise.customMonthlyDay != nil && !promise.customMonthlyTimes.isEmpty {
            _customFrequencyType = State(initialValue: .monthly)
        } else if !promise.customDailyTimes.isEmpty {
            _customFrequencyType = State(initialValue: .daily)
        } else {
            // Default to daily if nothing is set
            _customFrequencyType = State(initialValue: .daily)
        }
        
        // Initialize duration state
        if let durationDays = promise.durationDays {
            _hasDuration = State(initialValue: true)
            // Try to determine unit and value from duration
            if durationDays % 365 == 0 {
                _durationValue = State(initialValue: durationDays / 365)
                _durationUnit = State(initialValue: .years)
            } else if durationDays % 30 == 0 {
                _durationValue = State(initialValue: durationDays / 30)
                _durationUnit = State(initialValue: .months)
            } else if durationDays % 7 == 0 {
                _durationValue = State(initialValue: durationDays / 7)
                _durationUnit = State(initialValue: .weeks)
            } else {
                _durationValue = State(initialValue: durationDays)
                _durationUnit = State(initialValue: .days)
            }
        } else {
            _hasDuration = State(initialValue: false)
            _durationValue = State(initialValue: 30)
        }
    }
    
    private var profile: UserProfile {
        profiles.first ?? UserProfile()
    }
    
    var body: some View {
        ZStack {
            // Background
            Group {
                if isDarkMode {
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color(white: 0.1),
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.white
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Text("Edit Promise")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                    
                    Spacer()
                    
                    // Dark mode toggle button
                    Button {
                        isDarkMode.toggle()
                    } label: {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(white: 0.4))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill((isDarkMode ? Color.white : Color.black).opacity(0.1))
                            )
                    }
                    .padding(.trailing, 8)
                    
                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(white: 0.4))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill((isDarkMode ? Color.white : Color.black).opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    formContent
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                
                // Bottom Action Buttons
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((isDarkMode ? Color.white : Color.black).opacity(0.1))
                            )
                    }
                    
                    Button {
                        saveChanges()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.themeAccent)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            syncStateWithPromise()
        }
        .onChange(of: promise.customDailyTimes) { _, _ in
            syncStateWithPromise()
        }
        .onChange(of: promise.customWeeklyDays) { _, _ in
            syncStateWithPromise()
        }
        .onChange(of: promise.customWeeklyTimes) { _, _ in
            syncStateWithPromise()
        }
        .onChange(of: promise.customMonthlyDay) { _, _ in
            syncStateWithPromise()
        }
        .onChange(of: promise.customMonthlyTimes) { _, _ in
            syncStateWithPromise()
        }
        .onChange(of: promise.durationDays) { _, _ in
            syncStateWithPromise()
        }
        .onChange(of: promise.text) { _, _ in
            syncStateWithPromise()
        }
        .onChange(of: promise.id) { _, _ in
            // Sync when promise ID changes (indicates a different promise)
            syncStateWithPromise()
        }
        .alert("Delete Promise", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePromise()
            }
        } message: {
            Text("Are you sure you want to delete this promise? This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private var formContent: some View {
        VStack(spacing: 24) {
            // Current Schedule Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Current Schedule")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                    .padding(.bottom, 4)
                currentScheduleView
                    .id(scheduleViewId)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
            )
            
            // Completion Tracking Section
            if !promise.allNotificationTimes.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Completion Tracking")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                        .padding(.bottom, 4)
                    Text("Check off each notification time when you complete your promise")
                        .font(.system(size: 13))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                    
                    completionBoxesView
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                )
            }
            
            // Notification Schedule Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Notification Schedule")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                    .padding(.bottom, 4)
                Text("Configure your notification times")
                    .font(.system(size: 13))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                
                customFrequencyView
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
            )
            
            // Notification Agent Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Notification Agent")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                    .padding(.bottom, 4)
                Picker("Agent", selection: Binding(
                    get: { promise.notificationAgent },
                    set: { promise.notificationAgent = $0 }
                )) {
                    Text("None (Use default)").tag(nil as NotificationAgent?)
                    ForEach(agents) { agent in
                        Text(agent.name).tag(agent as NotificationAgent?)
                    }
                }
                .pickerStyle(.menu)
                .tint(isDarkMode ? Color.themeAccent : Color.themeAccent)
                
                if let agent = promise.notificationAgent {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personality:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                        Text(agent.personalityDescription)
                            .font(.system(size: 13))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                    }
                    .padding(.top, 4)
                } else {
                    Text("Default notifications will use a static message. Assign an agent for dynamic, personalized notifications.")
                        .font(.system(size: 13))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
            )
            
            // Duration Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Duration")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                    .padding(.bottom, 4)
                Toggle("Set Duration", isOn: $hasDuration)
                    .tint(Color.themeAccent)
                
                if hasDuration {
                    HStack {
                        Text("Duration")
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                        Spacer()
                        Stepper(value: $durationValue, in: 1...365) {
                            Text("\(durationValue)")
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                        .tint(Color.themeAccent)
                    }
                    
                    Picker("Unit", selection: $durationUnit) {
                        ForEach(DurationUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(isDarkMode ? Color.themeAccent : Color.themeAccent)
                    
                    if let endDate = calculateEndDate() {
                        Text("Ends: \(endDate, style: .date)")
                            .font(.system(size: 13))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                    }
                } else {
                    Text("No end date - promise continues indefinitely")
                        .font(.system(size: 13))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
            )
            
            // Delete Button Section
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Promise")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var scheduleViewId: String {
        let dailyCount = promise.customDailyTimes.count
        let weeklyCount = promise.customWeeklyTimes.count
        let monthlyCount = promise.customMonthlyTimes.count
        let weeklyDaysCount = promise.customWeeklyDays.count
        let monthlyDay = promise.customMonthlyDay ?? 0
        let duration = promise.durationDays ?? -1
        return "schedule_\(promise.id.uuidString)_\(dailyCount)_\(weeklyCount)_\(monthlyCount)_\(weeklyDaysCount)_\(monthlyDay)_\(duration)"
    }
    
    // MARK: - Helper Functions
    private func formatTime(_ time: Date) -> String {
        let (hour, minute) = DateUtils.timeComponents(from: time)
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let amPm = hour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", displayHour, minute, amPm)
    }
    
    private func formatWeeklyDays(_ days: [Int]) -> String {
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.sorted().map { weekdays[$0 - 1] }.joined(separator: ", ")
    }
    
    // MARK: - Completion Boxes View
    @ViewBuilder
    private var completionBoxesView: some View {
        let notificationTimes = promise.allNotificationTimes
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        VStack(alignment: .leading, spacing: 12) {
            // Show boxes for each notification time
            ForEach(Array(notificationTimes.enumerated()), id: \.offset) { index, notificationTime in
                let (hour, minute) = DateUtils.timeComponents(from: notificationTime)
                let timeString = formatTime(notificationTime)
                
                // Create a date for today at this notification time
                let todayAtTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? now
                
                // Check if this instance is completed
                let isCompleted = promise.isNotificationInstanceCompleted(for: todayAtTime)
                
                // Check if the notification time has passed (or if already completed, allow unchecking)
                let isTimePassed = todayAtTime <= now || isCompleted
                
                HStack(spacing: 12) {
                    // Checkbox
                    Button {
                        guard isTimePassed else { return } // Don't allow checking if time hasn't passed
                        
                        withAnimation {
                            if isCompleted {
                                promise.unmarkNotificationInstanceCompleted(for: todayAtTime)
                            } else {
                                promise.markNotificationInstanceCompleted(for: todayAtTime)
                            }
                            // Save changes
                            try? modelContext.save()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isCompleted ? Color.themeAccent : Color.clear)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            isCompleted 
                                                ? Color.themeAccent 
                                                : (isTimePassed 
                                                    ? (isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
                                                    : (isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.15))), 
                                            lineWidth: 2
                                        )
                                )
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!isTimePassed)
                    .opacity(isTimePassed ? 1.0 : 0.5)
                    
                    // Time label
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timeString)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isDarkMode ? .white : .black)
                            .opacity(isTimePassed ? 1.0 : 0.5)
                        
                        if !isTimePassed {
                            Text("Available after \(timeString)")
                                .font(.system(size: 11))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Current Schedule View
    @ViewBuilder
    private var currentScheduleView: some View {
        // Force observation of promise changes - access all properties to ensure SwiftUI observes them
        let _ = promise.customDailyTimes
        let _ = promise.customWeeklyTimes
        let _ = promise.customMonthlyTimes
        let _ = promise.customWeeklyDays
        let _ = promise.customMonthlyDay
        let _ = promise.durationDays
        let _ = promise.text
        
        // Check which frequency type is actually set
        let hasDaily = !promise.customDailyTimes.isEmpty
        let hasWeekly = !promise.customWeeklyDays.isEmpty && !promise.customWeeklyTimes.isEmpty
        let hasMonthly = promise.customMonthlyDay != nil && !promise.customMonthlyTimes.isEmpty
        
        if hasDaily {
            dailyScheduleView
        } else if hasWeekly {
            weeklyScheduleView
        } else if hasMonthly {
            monthlyScheduleView
        } else {
            Text("No schedule configured")
                .font(.system(size: 13))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
        }
    }
    
    @ViewBuilder
    private var dailyScheduleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency: Daily")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            Text("Times:")
                .font(.system(size: 13))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            ForEach(Array(promise.customDailyTimes.enumerated()), id: \.offset) { _, time in
                Text("• \(formatTime(time))")
                    .font(.system(size: 13))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            }
        }
    }
    
    @ViewBuilder
    private var weeklyScheduleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency: Weekly")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            Text("Days: \(formatWeeklyDays(promise.customWeeklyDays))")
                .font(.system(size: 13))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            Text("Times:")
                .font(.system(size: 13))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            ForEach(Array(promise.customWeeklyTimes.enumerated()), id: \.offset) { _, time in
                Text("• \(formatTime(time))")
                    .font(.system(size: 13))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            }
        }
    }
    
    @ViewBuilder
    private var monthlyScheduleView: some View {
        if let monthlyDay = promise.customMonthlyDay {
            VStack(alignment: .leading, spacing: 8) {
                Text("Frequency: Monthly")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                Text("Day of Month: \(monthlyDay)")
                    .font(.system(size: 13))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                Text("Times:")
                    .font(.system(size: 13))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                ForEach(Array(promise.customMonthlyTimes.enumerated()), id: \.offset) { _, time in
                    Text("• \(formatTime(time))")
                        .font(.system(size: 13))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Custom Frequency View
    @ViewBuilder
    private var customFrequencyView: some View {
        // Determine which type to show based on promise's current state
        // This ensures the UI reflects the actual promise state, not stale @State
        let activeType: CustomFrequencyType = {
            if !promise.customWeeklyDays.isEmpty && !promise.customWeeklyTimes.isEmpty {
                return .weekly
            } else if promise.customMonthlyDay != nil && !promise.customMonthlyTimes.isEmpty {
                return .monthly
            } else if !promise.customDailyTimes.isEmpty {
                return .daily
            } else {
                return customFrequencyType // Fallback to current state
            }
        }()
        
        Picker("Schedule Type", selection: $customFrequencyType) {
            ForEach(CustomFrequencyType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.themeAccent)
        .onAppear {
            // Sync state when picker appears (only on initial load)
            if activeType != customFrequencyType {
                customFrequencyType = activeType
            }
            syncStateWithPromise()
        }
        
        switch customFrequencyType {
        case .daily:
            customDailyView
        case .weekly:
            customWeeklyView
        case .monthly:
            customMonthlyView
        }
    }
    
    // MARK: - Custom Daily View
    @ViewBuilder
    private var customDailyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add notification times for every day")
                .font(.system(size: 13))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            
            ForEach(customDailyTimes.indices, id: \.self) { index in
                TimePickerRow(
                    index: index + 1,
                    time: Binding(
                        get: { customDailyTimes[index] },
                        set: { customDailyTimes[index] = $0 }
                    ),
                    onDelete: makeDeleteAction(for: index, in: $customDailyTimes),
                    isDarkMode: isDarkMode
                )
            }
            
            Button {
                withAnimation {
                    customDailyTimes.append(DateUtils.defaultTime())
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Time")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.themeAccent)
            }
        }
    }
    
    // MARK: - Custom Weekly View
    @ViewBuilder
    private var customWeeklyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select days and times (up to 5 times per day)")
                .font(.system(size: 13))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            
            // Weekday selector
            Text("Select Days")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            
            let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let isSelected = customWeeklyDays.contains(day)
                    Button {
                        // Use withAnimation and proper state update
                        withAnimation {
                            if customWeeklyDays.contains(day) {
                                customWeeklyDays.removeAll { $0 == day }
                            } else {
                                customWeeklyDays.append(day)
                                customWeeklyDays.sort()
                            }
                        }
                    } label: {
                        Text(weekdays[day - 1])
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.themeAccent : Color.themeSecondaryAccent.opacity(0.3))
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
                .background(isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
            
            // Times (up to 5)
            Text("Times")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            
            ForEach(customWeeklyTimes.indices, id: \.self) { index in
                TimePickerRow(
                    index: index + 1,
                    time: Binding(
                        get: { customWeeklyTimes[index] },
                        set: { customWeeklyTimes[index] = $0 }
                    ),
                    onDelete: makeDeleteAction(for: index, in: $customWeeklyTimes),
                    isDarkMode: isDarkMode
                )
            }
            
            if customWeeklyTimes.count < 5 {
                Button {
                    withAnimation {
                        customWeeklyTimes.append(DateUtils.defaultTime())
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Time")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.themeAccent)
                }
            } else {
                Text("Maximum 5 times per day")
                    .font(.system(size: 13))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            }
        }
    }
    
    // MARK: - Custom Monthly View
    @ViewBuilder
    private var customMonthlyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select day of month and notification times")
                .font(.system(size: 13))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            
            // Day of month picker
            HStack {
                Text("Day of Month")
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                Spacer()
                Picker("Day", selection: Binding(
                    get: { customMonthlyDay ?? 1 },
                    set: { customMonthlyDay = $0 }
                )) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.menu)
                .tint(isDarkMode ? Color.themeAccent : Color.themeAccent)
            }
            
            // Reminder count
            HStack {
                Text("Reminders per Month")
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                Spacer()
                Stepper("\(customMonthlyReminderCount)", value: $customMonthlyReminderCount, in: 1...31)
                    .tint(Color.themeAccent)
            }
            
            Divider()
                .background(isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
            
            // Times
            Text("Times")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            
            ForEach(customMonthlyTimes.indices, id: \.self) { index in
                TimePickerRow(
                    index: index + 1,
                    time: Binding(
                        get: { customMonthlyTimes[index] },
                        set: { customMonthlyTimes[index] = $0 }
                    ),
                    onDelete: makeDeleteAction(for: index, in: $customMonthlyTimes),
                    isDarkMode: isDarkMode
                )
            }
            
            Button {
                withAnimation {
                    customMonthlyTimes.append(DateUtils.defaultTime())
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Time")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.themeAccent)
            }
        }
    }
    
    private func calculateEndDate() -> Date? {
        guard hasDuration else { return nil }
        let totalDays = durationValue * durationUnit.daysMultiplier
        // Use current system date/time from device settings
        let now = Date()
        return Calendar.current.date(byAdding: .day, value: totalDays, to: now)
    }
    
    private func saveChanges() {
        // Capture notification message before any modifications
        let notificationMessage = promise.notificationMessage
        
        // Create copies of arrays to avoid SwiftData observation issues during assignment
        let dailyTimesCopy = Array(customDailyTimes)
        let weeklyDaysCopy = Array(customWeeklyDays)
        let weeklyTimesCopy = Array(customWeeklyTimes)
        let monthlyTimesCopy = Array(customMonthlyTimes)
        
        // Save all custom frequency settings (using copies)
        promise.customDailyTimes = dailyTimesCopy
        promise.customWeeklyDays = weeklyDaysCopy
        promise.customWeeklyTimes = weeklyTimesCopy
        promise.customMonthlyDay = customMonthlyDay
        promise.customMonthlyTimes = monthlyTimesCopy
        promise.customMonthlyReminderCount = customMonthlyReminderCount
        
        // Save duration
        if hasDuration {
            promise.durationDays = durationValue * durationUnit.daysMultiplier
        } else {
            promise.durationDays = nil
        }
        
        // Calculate next due date based on custom frequency (before saving)
        promise.due = DateUtils.calculateNextDueDate(for: promise)
        
        // Save changes first to ensure promise is in a consistent state
        do {
            try modelContext.save()
        } catch {
            dismiss()
            return
        }
        
        // Cancel existing notifications (after save to ensure promise is stable)
        // Use the captured ID to avoid accessing promise.id during potential observation issues
        NotificationManager.cancel(for: promise)
        
        // Schedule new notifications
        // If agent is assigned, pass nil so agent generation happens
        // Otherwise, use the static notificationMessage
        let messageToUse: String? = promise.notificationAgent != nil ? nil : notificationMessage
        NotificationManager.schedule(
            for: promise,
            with: messageToUse,
            userProfile: profile
        )
        
        dismiss()
    }
    
    private func makeDeleteAction(for index: Int, in array: Binding<[Date]>) -> (() -> Void)? {
        guard array.wrappedValue.count > 1 else { return nil }
        return {
            withAnimation {
                if index < array.wrappedValue.count {
                    array.wrappedValue.remove(at: index)
                }
            }
        }
    }
    
    private func deletePromise() {
        // Cancel notification
        NotificationManager.cancel(for: promise)
        
        // Delete promise
        modelContext.delete(promise)
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            // Failed to delete promise
        }
        
        dismiss()
    }
    
    @discardableResult
    private func syncStateWithPromise() -> Bool {
        // Sync @State variables with promise's current state
        // This ensures the UI reflects any external changes to the promise (e.g., from chat)
        
        // Sync frequency state
        if !promise.customDailyTimes.isEmpty {
            // Daily frequency is set
            // Always update to ensure UI reflects changes
            customDailyTimes = promise.customDailyTimes
            customFrequencyType = .daily
            // Clear other types
            customWeeklyDays = []
            customWeeklyTimes = []
            customMonthlyDay = nil
            customMonthlyTimes = []
            print("✅ Synced customDailyTimes: \(promise.customDailyTimes.count) times")
            for (index, time) in promise.customDailyTimes.enumerated() {
                let (hour, minute) = DateUtils.timeComponents(from: time)
                print("   [\(index)]: \(hour):\(minute)")
            }
        } else if !promise.customWeeklyDays.isEmpty && !promise.customWeeklyTimes.isEmpty {
            // Weekly frequency is set
            // Always update to ensure UI reflects changes
            customWeeklyDays = promise.customWeeklyDays
            customWeeklyTimes = promise.customWeeklyTimes
            customFrequencyType = .weekly
            // Clear other types
            customDailyTimes = []
            customMonthlyDay = nil
            customMonthlyTimes = []
        } else if promise.customMonthlyDay != nil && !promise.customMonthlyTimes.isEmpty {
            // Monthly frequency is set
            // Always update to ensure UI reflects changes
            customMonthlyDay = promise.customMonthlyDay
            customMonthlyTimes = promise.customMonthlyTimes
            customFrequencyType = .monthly
            // Clear other types
            customDailyTimes = []
            customWeeklyDays = []
            customWeeklyTimes = []
        } else {
            // No frequency set - default to daily
            customFrequencyType = .daily
        }
        
        // Sync duration state
        if let durationDays = promise.durationDays {
            let newHasDuration = true
            let newValue: Int
            let newUnit: DurationUnit
            
            // Calculate new values
            if durationDays % 365 == 0 {
                newValue = durationDays / 365
                newUnit = .years
            } else if durationDays % 30 == 0 {
                newValue = durationDays / 30
                newUnit = .months
            } else if durationDays % 7 == 0 {
                newValue = durationDays / 7
                newUnit = .weeks
            } else {
                newValue = durationDays
                newUnit = .days
            }
            
            // Update if changed
            if hasDuration != newHasDuration || durationValue != newValue || durationUnit != newUnit {
                hasDuration = newHasDuration
                durationValue = newValue
                durationUnit = newUnit
            }
        } else {
            // No duration
            if hasDuration {
                hasDuration = false
            }
        }
        
        return true
    }
    
}

// MARK: - Promise Chat Sheet
struct PromiseChatSheet: View {
    @Bindable var promise: Promise
    let profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: PromiseChatViewModel
    @State private var messageText = ""
    @State private var isDarkMode = false // Default to light mode
    @FocusState private var isInputFocused: Bool
    
    init(promise: Promise, profile: UserProfile) {
        self.promise = promise
        self.profile = profile
        // Create temporary context - will be updated in onAppear from environment
        let tempContainer = try! ModelContainer(for: Promise.self, UserProfile.self)
        let tempContext = ModelContext(tempContainer)
        // Pass promise for initial setup, but we won't store it in viewModel
        _viewModel = State(initialValue: PromiseChatViewModel(promise: promise, profile: profile, modelContext: tempContext))
    }
    
    private var welcomeMessageId: String {
        return "welcome_\(promise.id.uuidString)_\(promise.notificationMessage ?? "default")"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesListView
                inputBarView
            }
            .background(Color.themeBackground)
            .navigationTitle("Customize Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadMessages()
                viewModel.modelContext = modelContext
            }
            .onChange(of: viewModel.promiseUpdated) { _, updated in
                if updated {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.promiseUpdated = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private var messagesListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Welcome message
                    if viewModel.messages.isEmpty {
                        PromiseWelcomeMessageView(promise: promise)
                            .padding()
                            .id(welcomeMessageId)
                    }
                    
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, isDarkMode: isDarkMode)
                            .id(message.id)
                    }
                    
                    if viewModel.isLoading {
                        LoadingBubble(isDarkMode: isDarkMode)
                    }
                    
                    if let error = viewModel.errorMessage {
                        ErrorBubble(message: error, isDarkMode: isDarkMode)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.themeBackground)
    }
    
    @ViewBuilder
    private var inputBarView: some View {
        HStack(spacing: 12) {
            TextField("Describe the notification message you want...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(messageText.isEmpty ? Color.themeSecondaryAccent.opacity(0.5) : Color.themeAccent)
            }
            .disabled(messageText.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color.themeBackground.opacity(0.95))
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        Task {
            // Pass the @Bindable promise directly to ensure we modify the correct instance
            await viewModel.sendMessage(text, promise: promise)
        }
    }
}

// MARK: - Promise Welcome Message
struct PromiseWelcomeMessageView: View {
    @Bindable var promise: Promise
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "ellipsis.bubble.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeAccent, Color.themeSecondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Let's customize your notification")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text("\"\(promise.text)\"")
                .font(.body)
                .foregroundStyle(Color.themeSecondaryAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("I can help you customize the message content that appears in your notifications. What kind of message would you like to receive?")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}


