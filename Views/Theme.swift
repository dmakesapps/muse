import SwiftUI

// MARK: - Muse Design System
// Based on the battle plan color palette

extension Color {
    // MARK: - Primary Colors
    static let museDeepNavy = Color(hex: "1A1A1D")      // Main backgrounds
    static let museSoftWhite = Color(hex: "F5F5F7")     // Primary text
    static let museAccentBlue = Color(hex: "007AFF")   // CTAs, tab selection
    
    // MARK: - Gradient Colors
    static let museGradientStart = Color(hex: "6B4CE6") // Premium gradient start
    static let museGradientEnd = Color(hex: "4A90E2")  // Premium gradient end
    
    // MARK: - Secondary Colors
    static let museDarkGray = Color(hex: "2C2C2E")      // Card backgrounds
    static let museMediumGray = Color(hex: "48484A")   // Borders, dividers
    static let museLightGray = Color(hex: "8E8E93")    // Secondary text
    static let museSuccessGreen = Color(hex: "34C759") // Confirmations
    static let musePremiumGold = Color(hex: "FFD700")   // Premium badge
    static let museTeal = Color(hex: "5AC8FA")          // AI-generated content
    static let musePurple = Color(hex: "AF52DE")        // Accents
    static let museOrange = Color(hex: "FF9500")        // Alerts/Warmth
    
    // MARK: - Convenience Colors
    static let themeBackground = museDeepNavy
    static let themeText = museSoftWhite
    static let themeAccent = museAccentBlue
    static let themeSecondaryAccent = museTeal
    
    // Legacy support (will be removed later)
    static let themeOrange = museAccentBlue
    static let themeDarkGray = museDeepNavy
    static let themeLightBlue = museTeal
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let musePremiumGradient = LinearGradient(
        colors: [Color.museGradientStart, Color.museGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glassmorphism Style
struct GlassmorphismModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.museDarkGray.opacity(0.6))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                .ultraThinMaterial
                            )
                    )
            )
    }
}

extension View {
    func glassmorphism() -> some View {
        modifier(GlassmorphismModifier())
    }
    
    func rainbowBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF3B30"), // Red
                            Color(hex: "FF9500"), // Orange
                            Color(hex: "FFCC00"), // Yellow
                            Color(hex: "34C759"), // Green
                            Color(hex: "00C7BE"), // Teal
                            Color(hex: "007AFF"), // Blue
                            Color(hex: "AF52DE"), // Purple
                            Color(hex: "FF2D55")  // Pink
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Typography System
// Using SF Pro Rounded for a softer, more approachable feel perfect for wellness apps
extension Font {
    // MARK: - Display Fonts (Headings)
    static func museDisplayLarge() -> Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    static func museDisplayMedium() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    static func museDisplaySmall() -> Font {
        .system(size: 22, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Body Fonts
    static func museBodyLarge() -> Font {
        .system(size: 17, weight: .regular, design: .rounded)
    }
    
    static func museBodyMedium() -> Font {
        .system(size: 15, weight: .regular, design: .rounded)
    }
    
    static func museBodySmall() -> Font {
        .system(size: 13, weight: .regular, design: .rounded)
    }
    
    // MARK: - Accent Fonts
    static func museHeadline() -> Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }
    
    static func museSubheadline() -> Font {
        .system(size: 15, weight: .medium, design: .rounded)
    }
    
    static func museCaption() -> Font {
        .system(size: 12, weight: .regular, design: .rounded)
    }
    
    // MARK: - Special Fonts
    static func museQuote() -> Font {
        .system(size: 20, weight: .light, design: .rounded)
        .italic()
    }
    
    static func museAffirmation() -> Font {
        .system(size: 18, weight: .medium, design: .rounded)
    }
    
    // MARK: - Button Fonts
    static func museButtonLarge() -> Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }
    
    static func museButtonMedium() -> Font {
        .system(size: 15, weight: .semibold, design: .rounded)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


// MARK: - Pulsing Rainbow Border
// MARK: - Pulsing Rainbow Border
struct PulsingRainbowBorderModifier: ViewModifier {
    @State private var rotation: Double = 0
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    let maxDimension = max(geometry.size.width, geometry.size.height) * 2
                    
                    ZStack {
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "FF3B30"), // Red
                                Color(hex: "FF9500"), // Orange
                                Color(hex: "FFCC00"), // Yellow
                                Color(hex: "34C759"), // Green
                                Color(hex: "00C7BE"), // Teal
                                Color(hex: "007AFF"), // Blue
                                Color(hex: "AF52DE"), // Purple
                                Color(hex: "FF2D55"), // Pink
                                Color(hex: "FF3B30")  // Red (loop)
                            ]),
                            center: .center
                        )
                        .frame(width: maxDimension, height: maxDimension)
                        .rotationEffect(.degrees(rotation))
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .mask(
                    Capsule()
                        .stroke(lineWidth: 3) // Slightly thicker for "full" look
                )
                .scaleEffect(isPulsing ? 1.01 : 1.0) // Very subtle scale pulse
                .allowsHitTesting(false) // Prevent blocking touches on surrounding views
            )
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulsingRainbowBorder() -> some View {
        modifier(PulsingRainbowBorderModifier())
    }
}
