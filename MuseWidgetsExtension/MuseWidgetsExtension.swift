//
//  MuseWidgetsExtension.swift
//  MuseWidgetsExtension
//
//  Created by Davis on 12/13/25.
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

// MARK: - Quote Widget
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: WidgetQuote?
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: WidgetQuote(text: "The only way out is through.", author: "Robert Frost", category: "Wisdom"))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let quotes = SharedDataService.shared.loadSavedQuotes()
        let quote = quotes.randomElement() ?? WidgetQuote(text: "Save your favorite quotes to see them here.", author: "Muse", category: "Welcome")
        completion(QuoteEntry(date: Date(), quote: quote))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let quotes = SharedDataService.shared.loadSavedQuotes()
        var entries: [QuoteEntry] = []
        let currentDate = Date()
        
        if quotes.isEmpty {
            // Show placeholder if no saved quotes
            let entry = QuoteEntry(date: currentDate, quote: WidgetQuote(text: "Save your favorite quotes to see them here.", author: "Muse", category: "Welcome"))
            entries.append(entry)
        } else {
            // Cycle through saved quotes every hour
            for hourOffset in 0..<min(quotes.count, 24) {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let quote = quotes[hourOffset % quotes.count]
                entries.append(QuoteEntry(date: entryDate, quote: quote))
            }
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
            // Dark content area - thin rainbow border
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.12, green: 0.13, blue: 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(0.5) // Ultra thin rainbow border
            
            if let quote = entry.quote {
                VStack(spacing: 6) {
                    // Category tag
                    Text(quote.category.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8)) // Teal
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.15))
                        )
                    
                    Text(quote.text)
                        .font(.system(size: fontSize, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(family == .systemSmall ? 5 : 7)
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
            // Rainbow gradient fills entire widget background
            AngularGradient(
                colors: rainbowColors,
                center: .center,
                startAngle: .degrees(gradientRotation),
                endAngle: .degrees(gradientRotation + 360)
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
        AffirmationEntry(date: Date(), affirmation: WidgetAffirmation(text: "I am capable of achieving my goals.", category: "Confidence"))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> Void) {
        let affirmations = SharedDataService.shared.loadSavedAffirmations()
        let affirmation = affirmations.randomElement() ?? WidgetAffirmation(text: "Save your favorite affirmations to see them here.", category: "Welcome")
        completion(AffirmationEntry(date: Date(), affirmation: affirmation))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> Void) {
        let affirmations = SharedDataService.shared.loadSavedAffirmations()
        var entries: [AffirmationEntry] = []
        let currentDate = Date()
        
        if affirmations.isEmpty {
            let entry = AffirmationEntry(date: currentDate, affirmation: WidgetAffirmation(text: "Save your favorite affirmations to see them here.", category: "Welcome"))
            entries.append(entry)
        } else {
            // Cycle through saved affirmations every hour
            for hourOffset in 0..<min(affirmations.count, 24) {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let affirmation = affirmations[hourOffset % affirmations.count]
                entries.append(AffirmationEntry(date: entryDate, affirmation: affirmation))
            }
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
            // Dark content area - thin rainbow border
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.12, green: 0.13, blue: 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(0.5) // Ultra thin rainbow border
            
            if let affirmation = entry.affirmation {
                VStack(spacing: 6) {
                    // Category tag - purple for affirmations
                    Text(affirmation.category.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9)) // Purple
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.15))
                        )
                    
                    Text(affirmation.text)
                        .font(.system(size: fontSize, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(family == .systemSmall ? 5 : 7)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .containerBackground(for: .widget) {
            // Rainbow gradient fills entire widget background
            AngularGradient(
                colors: rainbowColors,
                center: .center,
                startAngle: .degrees(gradientRotation),
                endAngle: .degrees(gradientRotation + 360)
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
