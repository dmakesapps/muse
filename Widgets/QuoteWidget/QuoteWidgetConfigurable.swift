import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configuration Intent for Customizable Refresh Frequency
struct QuoteWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Quote Widget Configuration"
    static var description = IntentDescription("Configure your quote widget refresh frequency.")
    
    @Parameter(title: "Refresh Frequency")
    var refreshFrequency: RefreshFrequency
    
    enum RefreshFrequency: String, AppEnum {
        case everyMinute = "every_minute"
        case everyHour = "every_hour"
        case everyDay = "every_day"
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Refresh Frequency"
        
        static var caseDisplayRepresentations: [RefreshFrequency: DisplayRepresentation] = [
            .everyMinute: "Every Minute",
            .everyHour: "Every Hour",
            .everyDay: "Every Day"
        ]
        
        var timeInterval: TimeInterval {
            switch self {
            case .everyMinute: return 60
            case .everyHour: return 3600
            case .everyDay: return 86400
            }
        }
    }
}

// MARK: - Configurable Quote Widget
struct QuoteWidgetConfigurable: Widget {
    let kind: String = "QuoteWidgetConfigurable"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: QuoteWidgetConfiguration.self) { entry in
            QuoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quote Widget")
        .description("Display your saved quotes with customizable refresh frequency.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Configurable Provider
struct QuoteProviderConfigurable: AppIntentTimelineProvider {
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
    
    func snapshot(for configuration: QuoteWidgetConfiguration, in context: Context) async -> QuoteEntry {
        let quotes = SharedDataService.loadQuotes()
        let quote = quotes.randomElement() ?? Quote(
            text: "The only way out is through.",
            author: "Robert Frost",
            category: "Wisdom"
        )
        return QuoteEntry(date: Date(), quote: quote)
    }
    
    func timeline(for configuration: QuoteWidgetConfiguration, in context: Context) async -> Timeline<QuoteEntry> {
        let quotes = SharedDataService.loadQuotes()
        let frequency = configuration.refreshFrequency ?? .everyHour
        
        var entries: [QuoteEntry] = []
        let currentDate = Date()
        
        // Create entries based on selected frequency
        let interval = frequency.timeInterval
        let numberOfEntries: Int
        
        switch frequency {
        case .everyMinute:
            numberOfEntries = 60 // 1 hour of entries
        case .everyHour:
            numberOfEntries = 24 // 24 hours of entries
        case .everyDay:
            numberOfEntries = 7 // 7 days of entries
        }
        
        for i in 0..<numberOfEntries {
            let entryDate = currentDate.addingTimeInterval(interval * Double(i))
            let quote = quotes.randomElement() ?? Quote(
                text: "The only way out is through.",
                author: "Robert Frost",
                category: "Wisdom"
            )
            entries.append(QuoteEntry(date: entryDate, quote: quote))
        }
        
        // Set policy based on frequency
        let policy: TimelineReloadPolicy
        switch frequency {
        case .everyMinute:
            policy = .after(Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!)
        case .everyHour:
            policy = .after(Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!)
        case .everyDay:
            policy = .after(Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        }
        
        return Timeline(entries: entries, policy: policy)
    }
}


