import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isDarkMode: Bool
    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How Pacto Works")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                        
                        Text("Your guide to getting started with Pacto")
                            .font(.system(size: 16))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Section 1: Chat with Pacto
                    HelpSection(
                        title: "Chat with Pacto Assistant",
                        icon: "message.fill",
                        isDarkMode: isDarkMode
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Start by chatting with the Pacto assistant to create promises or goals for the future. Simply type what you want to commit to, and the assistant will help you set it up.")
                                .font(.system(size: 15))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                .lineSpacing(4)
                            
                            Text("Example:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                                .padding(.top, 8)
                            
                            Text("\"I want to stretch every morning at 7am\"")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.themeAccent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.themeAccent.opacity(0.1))
                                )
                        }
                    }
                    
                    // Section 2: Frequencies and Types
                    HelpSection(
                        title: "Promise Frequencies & Types",
                        icon: "calendar",
                        isDarkMode: isDarkMode
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pacto supports different types of promises with flexible scheduling:")
                                .font(.system(size: 15))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                .lineSpacing(4)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HelpFeatureRow(
                                    title: "Daily Promises",
                                    description: "Set multiple reminders throughout each day. Perfect for habits like drinking water, taking breaks, or daily exercises.",
                                    icon: "sun.max.fill",
                                    isDarkMode: isDarkMode
                                )
                                
                                HelpFeatureRow(
                                    title: "Weekly Promises",
                                    description: "Choose specific days of the week and times. Great for weekly workouts, meetings, or recurring tasks.",
                                    icon: "calendar.badge.clock",
                                    isDarkMode: isDarkMode
                                )
                                
                                HelpFeatureRow(
                                    title: "Monthly Promises",
                                    description: "Set reminders for specific days of the month. Ideal for monthly reviews, bills, or special occasions.",
                                    icon: "calendar",
                                    isDarkMode: isDarkMode
                                )
                            }
                        }
                    }
                    
                    // Section 3: Creating Agents
                    HelpSection(
                        title: "Create Notification Agents",
                        icon: "person.fill",
                        isDarkMode: isDarkMode
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Agents are personalized notification personalities that deliver your reminders in unique voices. Tap the + button in the top center to create a new agent.")
                                .font(.system(size: 15))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                .lineSpacing(4)
                            
                            Text("You can:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                                .padding(.top, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HelpBulletPoint(
                                    text: "Name your agent (e.g., \"Motivational Coach\", \"Strict Trainer\")",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Describe their personality and communication style",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Assign agents to specific promises for personalized notifications",
                                    isDarkMode: isDarkMode
                                )
                            }
                        }
                    }
                    
                    // Section 4: Programming Personality
                    HelpSection(
                        title: "Program Agent Personality",
                        icon: "brain.head.profile",
                        isDarkMode: isDarkMode
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When creating an agent, you'll be asked to describe their personality. Be specific about:")
                                .font(.system(size: 15))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                .lineSpacing(4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HelpBulletPoint(
                                    text: "Tone (encouraging, strict, friendly, professional)",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Communication style (short and direct, longer and motivational)",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Energy level (high energy, calm, intense)",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Specific phrases or words they use",
                                    isDarkMode: isDarkMode
                                )
                            }
                            
                            Text("The assistant will ask clarifying questions to ensure your agent matches your vision perfectly.")
                                .font(.system(size: 14))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                                .padding(.top, 8)
                        }
                    }
                    
                    // Section 5: Promise Settings
                    HelpSection(
                        title: "Edit Promise Settings",
                        icon: "slider.horizontal.3",
                        isDarkMode: isDarkMode
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tap on any promise in the Promises list to open its settings. Here you can:")
                                .font(.system(size: 15))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                .lineSpacing(4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HelpBulletPoint(
                                    text: "Change notification frequency (daily, weekly, monthly)",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Adjust notification times",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Assign or change notification agents",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Set duration for time-limited promises",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Check off completion boxes after completing your promise",
                                    isDarkMode: isDarkMode
                                )
                            }
                            
                            Text("Completion boxes appear for each notification time. Check them off when you complete your promise, or tap \"I Kept It!\" from the notification itself.")
                                .font(.system(size: 14))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                                .padding(.top, 8)
                        }
                    }
                    
                    // Section 6: Schedule Page
                    HelpSection(
                        title: "Schedule & Progress",
                        icon: "chart.bar.fill",
                        isDarkMode: isDarkMode
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Schedule page shows your progress and activity over time:")
                                .font(.system(size: 15))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                .lineSpacing(4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HelpBulletPoint(
                                    text: "Activity heatmap: Visual calendar showing your completion activity",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Daily schedule: See all promises scheduled for a selected day",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Completion percentage: Shows how many notifications you've completed for each promise that day",
                                    isDarkMode: isDarkMode
                                )
                                HelpBulletPoint(
                                    text: "Next notification time: Displays the closest upcoming notification for each promise",
                                    isDarkMode: isDarkMode
                                )
                            }
                            
                            Text("Tap on any day in the heatmap to see your schedule for that day. The darker green squares indicate more activity and completions.")
                                .font(.system(size: 14))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
        }
    }
}

// MARK: - Help Section Component
struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let isDarkMode: Bool
    let content: Content
    
    init(title: String, icon: String, isDarkMode: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.isDarkMode = isDarkMode
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.themeAccent)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.themeAccent.opacity(0.15))
                    )
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Help Feature Row
struct HelpFeatureRow: View {
    let title: String
    let description: String
    let icon: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.themeAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Help Bullet Point
struct HelpBulletPoint: View {
    let text: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.themeAccent)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}



