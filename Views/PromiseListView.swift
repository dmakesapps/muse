import SwiftUI
import SwiftData

struct PromiseListView: View {
    @Query(sort: \Promise.due) private var promises: [Promise]
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Binding var isDarkMode: Bool
    @State private var showCreateSheet = false
    
    init(isDarkMode: Binding<Bool> = .constant(false)) {
        self._isDarkMode = isDarkMode
    }
    
    private var profile: UserProfile {
        profiles.first ?? UserProfile()
    }
    
    var body: some View {
        ZStack {
            // Background
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
                VStack(spacing: 12) {
                    // Promises List
                    if promises.isEmpty {
                        ContentUnavailableView(
                            "No Promises Yet",
                            systemImage: "checkmark.circle",
                            description: Text("Chat with your AI coach to create your first promise!")
                        )
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(promises) { promise in
                                PromiseListItemView(
                                    promise: promise,
                                    profile: profile,
                                    modelContext: modelContext,
                                    isDarkMode: $isDarkMode
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Promises")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.themeAccent)
                    }
                    
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
        .sheet(isPresented: $showCreateSheet) {
            PromiseCreateSheet(isDarkMode: $isDarkMode)
        }
    }
}

struct PromiseListItemView: View {
    @Bindable var promise: Promise
    let profile: UserProfile
    let modelContext: ModelContext
    @Binding var isDarkMode: Bool
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showEditSheet = false
    @State private var showChatSheet = false
    
    var body: some View {
        Button {
            showEditSheet = true
        } label: {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.themeAccent.opacity(0.2),
                                    Color.themeAccent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconForPromise)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.themeAccent)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(promise.text)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isDarkMode ? Color.white : Color.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        // Badge
                        if let badge = badgeForPromise {
                            Text(badge.text)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(badge.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(badge.backgroundColor)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let description = descriptionForPromise {
                        Text(description)
                            .font(.system(size: 15))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Time - using Text with relative style for auto-updating
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(promise.due, style: .relative)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                    .padding(.top, 2)
                    .id(currentTime) // Force update when currentTime changes
                }
                
                Spacer()
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
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditSheet) {
            PromiseEditSheet(promise: promise, isDarkMode: $isDarkMode)
        }
        .sheet(isPresented: $showChatSheet) {
            PromiseChatSheet(promise: promise, profile: profile)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deletePromise()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button("Kept") {
                markKept()
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading) {
            Button {
                showChatSheet = true
            } label: {
                Label("Chat", systemImage: "ellipsis.bubble")
            }
            .tint(Color.themeAccent)
            
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color.themeAccent)
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
    
    private var iconForPromise: String {
        // Use different icons based on promise content or status
        if promise.kept > 0 {
            return "flame.fill"
        }
        return "target"
    }
    
    private var badgeForPromise: (text: String, color: Color, backgroundColor: Color)? {
        if promise.isExpired {
            return ("Expired", Color.red, Color.red.opacity(0.1))
        }
        if promise.score >= 80 {
            return ("On Track", Color.green, Color.green.opacity(0.1))
        }
        return nil
    }
    
    private var descriptionForPromise: String? {
        if let context = promise.userContext {
            return context
        }
        if let notification = promise.notificationMessage {
            return "💬 \"\(notification)\""
        }
        return nil
    }
    
    private func markKept() {
        promise.kept += 1
        promise.total += 1
        promise.lastKeptAt = Date()
        profile.totalKept += 1
        promise.due = DateUtils.calculateNextDueDate(for: promise)
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
    }
    
    private func deletePromise() {
        NotificationManager.cancel(for: promise)
        modelContext.delete(promise)
        try? modelContext.save()
    }
    
}

// MARK: - Promise Create Sheet
struct PromiseCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Binding var isDarkMode: Bool
    
    @State private var promiseText = ""
    @State private var contextText = ""
    @FocusState private var isPromiseTextFocused: Bool
    
    private var profile: UserProfile {
        profiles.first ?? UserProfile()
    }
    
    private var canSave: Bool {
        !promiseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                    Text("New Promise")
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
                    VStack(alignment: .leading, spacing: 24) {
                        // Promise Text Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Promise")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                            
                            TextField("e.g., Stretch daily, Read each night", text: $promiseText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .foregroundColor(isDarkMode ? .white : .black)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                                )
                                .focused($isPromiseTextFocused)
                                .lineLimit(2...4)
                        }
                        
                        // Context Section (Optional)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Why this matters (Optional)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                            
                            TextField("e.g., I am doing this to be healthier", text: $contextText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .foregroundColor(isDarkMode ? .white : .black)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                                )
                                .lineLimit(2...4)
                        }
                    }
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
                        createPromise()
                    } label: {
                        Text("Create")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(canSave ? Color.themeAccent : Color.themeAccent.opacity(0.5))
                            )
                    }
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Focus the promise text field when sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPromiseTextFocused = true
            }
        }
    }
    
    private func createPromise() {
        let trimmedText = promiseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let trimmedContext = contextText.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = trimmedContext.isEmpty ? nil : trimmedContext
        
        // Create a default due date (tomorrow at 9 AM)
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let defaultDue = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        
        // Create the promise
        let promise = Promise(
            text: trimmedText,
            due: defaultDue,
            context: context
        )
        
        // Set default daily notification time (9 AM)
        promise.customDailyTimes = [DateUtils.defaultTime()]
        
        // Insert into model context
        modelContext.insert(promise)
        
        // Save
        do {
            try modelContext.save()
            
            // Schedule notification
            Task {
                do {
                    let notificationMessage = try await AICoachService.generateNotificationMessage(
                        for: promise,
                        userProfile: profile
                    )
                    promise.notificationMessage = notificationMessage
                    NotificationManager.schedule(for: promise, with: notificationMessage, userProfile: profile)
                } catch {
                    NotificationManager.schedule(for: promise, with: nil, userProfile: profile)
                }
            }
            
            dismiss()
        } catch {
            // Handle error - could show an alert here
            print("Failed to create promise: \(error)")
        }
    }
}

