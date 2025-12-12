import WidgetKit
import SwiftUI

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quote Widget")
        .description("Display your saved quotes on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled() // Remove default margins
    }
}

struct QuoteProvider: TimelineProvider {
    // Default refresh: every hour
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(
            date: Date(),
            quote: Quote(
                text: "The only way out is through.",
                author: "Robert Frost",
                category: "Wisdom"
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let quotes = SharedDataService.loadQuotes()
        // Only use saved quotes
        let quote = quotes.randomElement() ?? Quote(
            text: "Save quotes in the app to see them here.",
            author: "Muse",
            category: "Tip"
        )
        let entry = QuoteEntry(date: Date(), quote: quote)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        let quotes = SharedDataService.loadQuotes()
        
        // Only use saved quotes - don't show defaults if user has saved items
        guard !quotes.isEmpty else {
            // If no saved quotes, create empty timeline (widget will show placeholder)
            let timeline = Timeline<QuoteEntry>(entries: [], policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date())!))
            completion(timeline)
            return
        }
        
        var entries: [QuoteEntry] = []
        let currentDate = Date()
        
        // Create entries for the next 24 hours, refreshing every hour
        // Shuffle quotes to ensure variety
        let shuffledQuotes = quotes.shuffled()
        var quoteIndex = 0
        
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            // Cycle through shuffled quotes
            let quote = shuffledQuotes[quoteIndex % shuffledQuotes.count]
            quoteIndex += 1
            entries.append(QuoteEntry(date: entryDate, quote: quote))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

struct QuoteWidgetEntryView: View {
    var entry: QuoteProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // Full background - fills entire widget space
            Color.museDeepNavy
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: spacing) {
                // Category badge
                Text(entry.quote.category.uppercased())
                    .font(.system(size: categoryFontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.museTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.museTeal.opacity(0.2))
                    )
                
                // Quote text
                Text(entry.quote.text)
                    .font(.system(size: quoteFontSize, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(quoteLineLimit)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // Author
                Text("— \(entry.quote.author)")
                    .font(.system(size: authorFontSize, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .containerBackground(Color.museDeepNavy, for: .widget)
    }
    
    // Responsive sizing based on widget family
    private var spacing: CGFloat {
        switch family {
        case .systemSmall: return 8
        case .systemMedium: return 10
        case .systemLarge: return 12
        default: return 10
        }
    }
    
    private var padding: CGFloat {
        switch family {
        case .systemSmall: return 12
        case .systemMedium: return 14
        case .systemLarge: return 16
        default: return 14
        }
    }
    
    private var categoryFontSize: CGFloat {
        switch family {
        case .systemSmall: return 9
        case .systemMedium: return 10
        case .systemLarge: return 11
        default: return 10
        }
    }
    
    private var quoteFontSize: CGFloat {
        switch family {
        case .systemSmall: return 14
        case .systemMedium: return 16
        case .systemLarge: return 18
        default: return 16
        }
    }
    
    private var authorFontSize: CGFloat {
        switch family {
        case .systemSmall: return 10
        case .systemMedium: return 12
        case .systemLarge: return 13
        default: return 12
        }
    }
    
    private var quoteLineLimit: Int? {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 6
        case .systemLarge: return nil
        default: return 6
        }
    }
}

#Preview(as: .systemSmall) {
    QuoteWidget()
} timeline: {
    QuoteEntry(
        date: Date(),
        quote: Quote(
            text: "The only way out is through.",
            author: "Robert Frost",
            category: "Wisdom"
        )
    )
}

