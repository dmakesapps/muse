import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var isPresented: Bool
    let isDarkMode: Bool
    let onToggleDarkMode: () -> Void
    let onShowAgentCreation: () -> Void
    let onNavigateToPromises: () -> Void
    let onNavigateToSchedule: () -> Void
    @Query(sort: \Message.timestamp, order: .reverse) private var recentMessages: [Message]
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background overlay
            Color.black.opacity(isPresented ? 0.3 : 0)
                .ignoresSafeArea(.all)
                .allowsHitTesting(isPresented)
                .onTapGesture {
                    if isPresented {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                }
            
            GeometryReader { geometry in
                let sidebarWidth: CGFloat = min(geometry.size.width * 0.8, 300) // 80% of screen, max 300
                
                // Sidebar
                VStack(alignment: .leading, spacing: 0) {
                    // Header with title and new chat button
                    HStack(alignment: .center) {
                        Text("Pacto")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(white: 0.4))
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill((isDarkMode ? Color.white : Color.black).opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 50)
                    .padding(.bottom, 24)
                    
                    // Main Navigation Links
                    VStack(alignment: .leading, spacing: 0) {
                        // Create Agent
                        SidebarNavItem(
                            icon: "plus",
                            title: "Create Agent",
                            isDarkMode: isDarkMode,
                            action: {
                                onShowAgentCreation()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }
                        )
                        
                        // Promises
                        SidebarNavItem(
                            icon: "list.bullet",
                            title: "Promises",
                            isDarkMode: isDarkMode,
                            action: {
                                onNavigateToPromises()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }
                        )
                        
                        // Schedule
                        SidebarNavItem(
                            icon: "calendar",
                            title: "Schedule",
                            isDarkMode: isDarkMode,
                            action: {
                                onNavigateToSchedule()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }
                        )
                    }
                    .padding(.bottom, 24)
                    
                    // Recents Section
                    if !recentMessages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recents")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                                .padding(.horizontal, 16)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(recentMessages.prefix(10))) { message in
                                        Button {
                                            // Close sidebar when clicking on recent message
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isPresented = false
                                            }
                                        } label: {
                                            HStack(spacing: 8) {
                                                Text(truncateMessage(message.content))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    Spacer()
                    
                    // Dark mode toggle section (fixed at bottom)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Spacer()
                            
                            // Dark mode toggle button (moved to bottom)
                            Button {
                                onToggleDarkMode()
                            } label: {
                                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
                .frame(width: sidebarWidth)
                .frame(height: geometry.size.height)
                .background(
                    isDarkMode 
                        ? Color(white: 0.12)
                        : Color(white: 0.98)
                )
                .offset(x: isPresented ? 0 : -sidebarWidth)
            }
        }
        .ignoresSafeArea(.all)
        .allowsHitTesting(isPresented)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func truncateMessage(_ text: String) -> String {
        if text.count > 40 {
            return String(text.prefix(37)) + "..."
        }
        return text
    }
}

// MARK: - Sidebar Navigation Item
struct SidebarNavItem: View {
    let icon: String
    let title: String
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isDarkMode ? .white : Color(white: 0.2))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

