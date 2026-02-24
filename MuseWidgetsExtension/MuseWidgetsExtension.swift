//
//  MuseWidgetsExtension.swift
//  MuseWidgetsExtension
//
//  Created by Davis on 12/13/26.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data Service
class SharedDataService {
    static let shared = SharedDataService()
    private let appGroupIdentifier = "group.Ephesian28LLC.Muse"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    func loadSavedQuotes() -> [WidgetQuote] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "savedQuotes") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([WidgetQuote].self, from: data)
        } catch {
            print("Error decoding quotes: \(error)")
            return []
        }
    }
    
    func loadSavedAffirmations() -> [WidgetAffirmation] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "savedAffirmations") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([WidgetAffirmation].self, from: data)
        } catch {
            print("Error decoding affirmations: \(error)")
            return []
        }
    }
}

// MARK: - Widget Models
struct WidgetQuote: Codable, Identifiable {
    let id: UUID
    let text: String
    let author: String
    let category: String
    
    init(id: UUID = UUID(), text: String, author: String, category: String) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
    }
}

struct WidgetAffirmation: Codable, Identifiable {
    let id: UUID
    let text: String
    let category: String
    
    init(id: UUID = UUID(), text: String, category: String) {
        self.id = id
        self.text = text
        self.category = category
    }
}

// MARK: - Default Content (shown when user hasn't saved any)
struct DefaultContent {
    static let quotes: [WidgetQuote] = [
        WidgetQuote(text: "The privilege of a lifetime is to become who you truly are.", author: "Carl Jung", category: "Wisdom"),
        WidgetQuote(text: "What you seek is seeking you.", author: "Rumi", category: "Purpose"),
        WidgetQuote(text: "The only way out is through.", author: "Robert Frost", category: "Growth"),
        WidgetQuote(text: "Be the change you wish to see in the world.", author: "Mahatma Gandhi", category: "Purpose"),
        WidgetQuote(text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein", category: "Growth"),
        WidgetQuote(text: "The mind is everything. What you think you become.", author: "Buddha", category: "Wisdom"),
        WidgetQuote(text: "Your task is not to seek for love, but to find all the barriers you have built against it.", author: "Rumi", category: "Love"),
        WidgetQuote(text: "Until you make the unconscious conscious, it will direct your life.", author: "Carl Jung", category: "Self-Discovery"),
        WidgetQuote(text: "Life isn't about finding yourself. Life is about creating yourself.", author: "George Bernard Shaw", category: "Purpose"),
        WidgetQuote(text: "The present moment is the only moment available to us.", author: "Thich Nhat Hanh", category: "Mindfulness"),
        WidgetQuote(text: "Realize deeply that the present moment is all you ever have.", author: "Eckhart Tolle", category: "Presence"),
        WidgetQuote(text: "You are not a drop in the ocean. You are the entire ocean in a drop.", author: "Rumi", category: "Self-Worth"),
    ]
    
    static let affirmations: [WidgetAffirmation] = [
        WidgetAffirmation(text: "I am worthy of love and belonging.", category: "Self-Worth"),
        WidgetAffirmation(text: "I trust the journey of my life.", category: "Trust"),
        WidgetAffirmation(text: "I am capable of achieving my goals.", category: "Confidence"),
        WidgetAffirmation(text: "I release what no longer serves me.", category: "Letting Go"),
        WidgetAffirmation(text: "I am exactly where I need to be.", category: "Trust"),
        WidgetAffirmation(text: "I choose peace over worry.", category: "Peace"),
        WidgetAffirmation(text: "I am growing stronger every day.", category: "Growth"),
        WidgetAffirmation(text: "I attract positive energy into my life.", category: "Abundance"),
        WidgetAffirmation(text: "I am grateful for this moment.", category: "Gratitude"),
        WidgetAffirmation(text: "I believe in my ability to succeed.", category: "Confidence"),
        WidgetAffirmation(text: "I am open to new possibilities.", category: "Openness"),
        WidgetAffirmation(text: "I radiate love and positivity.", category: "Love"),
    ]
}

// MARK: - Quote Widget
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: WidgetQuote?
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: DefaultContent.quotes.randomElement()!)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let savedQuotes = SharedDataService.shared.loadSavedQuotes()
        // Use saved quotes if available, otherwise use defaults
        let quotes = savedQuotes.isEmpty ? DefaultContent.quotes : savedQuotes
        let quote = quotes.randomElement()!
        completion(QuoteEntry(date: Date(), quote: quote))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let savedQuotes = SharedDataService.shared.loadSavedQuotes()
        // Use saved quotes if available, otherwise use defaults
        let quotes = savedQuotes.isEmpty ? DefaultContent.quotes : savedQuotes
        
        var entries: [QuoteEntry] = []
        let currentDate = Date()
        
        // Shuffle and cycle through quotes every hour
        let shuffledQuotes = quotes.shuffled()
        for hourOffset in 0..<min(shuffledQuotes.count, 24) {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let quote = shuffledQuotes[hourOffset % shuffledQuotes.count]
            entries.append(QuoteEntry(date: entryDate, quote: quote))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct QuoteWidgetEntryView: View {
    var entry: QuoteProvider.Entry
    @Environment(\.widgetFamily) var family
    
    // Rainbow colors
    private let rainbowColors: [Color] = [
        Color(red: 1.0, green: 0.3, blue: 0.3),   // Red
        Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange
        Color(red: 1.0, green: 0.9, blue: 0.3),   // Yellow
        Color(red: 0.3, green: 0.9, blue: 0.4),   // Green
        Color(red: 0.3, green: 0.7, blue: 1.0),   // Blue
        Color(red: 0.6, green: 0.4, blue: 1.0),   // Purple
        Color(red: 1.0, green: 0.4, blue: 0.8),   // Pink
        Color(red: 1.0, green: 0.3, blue: 0.3),   // Red (loop)
    ]
    
    // Shift gradient based on time for animation effect
    private var gradientRotation: Double {
        let seconds = Calendar.current.component(.second, from: entry.date)
        return Double(seconds) * 6 // 360 degrees per minute
    }
    
    var body: some View {
        ZStack {
            // Rainbow stroke overlay on dark background
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    AngularGradient(
                        colors: rainbowColors,
                        center: .center,
                        startAngle: .degrees(gradientRotation),
                        endAngle: .degrees(gradientRotation + 360)
                    ),
                    lineWidth: 3
                )
            
            if let quote = entry.quote {
                VStack(spacing: 8) {
                    Text(quote.text)
                        .font(.system(size: fontSize, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(family == .systemSmall ? 6 : 8)
                        .minimumScaleFactor(0.6)
                    
                    Text("— \(quote.author)")
                        .font(.system(size: fontSize * 0.55, weight: .regular, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .containerBackground(for: .widget) {
            // Dark background fills edge to edge
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.12, green: 0.13, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var fontSize: CGFloat {
        switch family {
        case .systemSmall: return 15
        case .systemMedium: return 18
        case .systemLarge: return 22
        default: return 16
        }
    }
}

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quotes")
        .description("Display your saved quotes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Affirmation Widget
struct AffirmationEntry: TimelineEntry {
    let date: Date
    let affirmation: WidgetAffirmation?
}

struct AffirmationProvider: TimelineProvider {
    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(date: Date(), affirmation: DefaultContent.affirmations.randomElement()!)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> Void) {
        let savedAffirmations = SharedDataService.shared.loadSavedAffirmations()
        // Use saved affirmations if available, otherwise use defaults
        let affirmations = savedAffirmations.isEmpty ? DefaultContent.affirmations : savedAffirmations
        let affirmation = affirmations.randomElement()!
        completion(AffirmationEntry(date: Date(), affirmation: affirmation))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> Void) {
        let savedAffirmations = SharedDataService.shared.loadSavedAffirmations()
        // Use saved affirmations if available, otherwise use defaults
        let affirmations = savedAffirmations.isEmpty ? DefaultContent.affirmations : savedAffirmations
        
        var entries: [AffirmationEntry] = []
        let currentDate = Date()
        
        // Shuffle and cycle through affirmations every hour
        let shuffledAffirmations = affirmations.shuffled()
        for hourOffset in 0..<min(shuffledAffirmations.count, 24) {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let affirmation = shuffledAffirmations[hourOffset % shuffledAffirmations.count]
            entries.append(AffirmationEntry(date: entryDate, affirmation: affirmation))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct AffirmationWidgetEntryView: View {
    var entry: AffirmationProvider.Entry
    @Environment(\.widgetFamily) var family
    
    // Rainbow colors
    private let rainbowColors: [Color] = [
        Color(red: 1.0, green: 0.3, blue: 0.3),   // Red
        Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange
        Color(red: 1.0, green: 0.9, blue: 0.3),   // Yellow
        Color(red: 0.3, green: 0.9, blue: 0.4),   // Green
        Color(red: 0.3, green: 0.7, blue: 1.0),   // Blue
        Color(red: 0.6, green: 0.4, blue: 1.0),   // Purple
        Color(red: 1.0, green: 0.4, blue: 0.8),   // Pink
        Color(red: 1.0, green: 0.3, blue: 0.3),   // Red (loop)
    ]
    
    // Shift gradient based on time for animation effect
    private var gradientRotation: Double {
        let seconds = Calendar.current.component(.second, from: entry.date)
        return Double(seconds) * 6 // 360 degrees per minute
    }
    
    var body: some View {
        ZStack {
            // Rainbow stroke overlay on dark background
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    AngularGradient(
                        colors: rainbowColors,
                        center: .center,
                        startAngle: .degrees(gradientRotation),
                        endAngle: .degrees(gradientRotation + 360)
                    ),
                    lineWidth: 3
                )
            
            if let affirmation = entry.affirmation {
                VStack(spacing: 8) {
                    Text(affirmation.text)
                        .font(.system(size: fontSize, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(family == .systemSmall ? 6 : 8)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .containerBackground(for: .widget) {
            // Dark background fills edge to edge
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.12, green: 0.13, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var fontSize: CGFloat {
        switch family {
        case .systemSmall: return 16
        case .systemMedium: return 19
        case .systemLarge: return 24
        default: return 17
        }
    }
}

struct AffirmationWidget: Widget {
    let kind: String = "AffirmationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AffirmationProvider()) { entry in
            AffirmationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Affirmations")
        .description("Display your saved affirmations.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview("Quote Small", as: .systemSmall) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: .now, quote: WidgetQuote(text: "The only way out is through.", author: "Robert Frost", category: "Wisdom"))
}

#Preview("Affirmation Small", as: .systemSmall) {
    AffirmationWidget()
} timeline: {
    AffirmationEntry(date: .now, affirmation: WidgetAffirmation(text: "I am capable of achieving my goals.", category: "Confidence"))
}
