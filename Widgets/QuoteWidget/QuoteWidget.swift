import WidgetKit
import SwiftUI

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quote Widget")
        .description("Display your saved quotes on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
        let quote = quotes.randomElement() ?? Quote(
            text: "The only way out is through.",
            author: "Robert Frost",
            category: "Wisdom"
        )
        let entry = QuoteEntry(date: Date(), quote: quote)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        let quotes = SharedDataService.loadQuotes()
        
        var entries: [QuoteEntry] = []
        let currentDate = Date()
        
        // Create entries for the next 24 hours, refreshing every hour
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let quote = quotes.randomElement() ?? Quote(
                text: "The only way out is through.",
                author: "Robert Frost",
                category: "Wisdom"
            )
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
    
    var body: some View {
        ZStack {
            // Background with glassmorphism effect
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .background(.ultraThinMaterial)
            
            VStack(alignment: .leading, spacing: 12) {
                // Category badge
                Text(entry.quote.category.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.museTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.museTeal.opacity(0.2))
                    )
                
                // Quote text
                Text(entry.quote.text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Author
                Text("— \(entry.quote.author)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(16)
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

