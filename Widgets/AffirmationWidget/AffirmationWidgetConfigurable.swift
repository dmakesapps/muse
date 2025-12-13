import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configuration Intent for Customizable Refresh Frequency
struct AffirmationWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Affirmation Widget Configuration"
    static var description = IntentDescription("Configure your affirmation widget refresh frequency.")
    
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

// MARK: - Configurable Affirmation Widget
struct AffirmationWidgetConfigurable: Widget {
    let kind: String = "AffirmationWidgetConfigurable"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: AffirmationWidgetConfiguration.self) { entry in
            AffirmationWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Affirmation Widget")
        .description("Display your saved affirmations with customizable refresh frequency.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Configurable Provider
struct AffirmationProviderConfigurable: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(
            date: Date(),
            affirmation: Affirmation(
                text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
                category: "Confidence"
            )
        )
    }
    
    func snapshot(for configuration: AffirmationWidgetConfiguration, in context: Context) async -> AffirmationEntry {
        let affirmations = SharedDataService.loadAffirmations()
        let affirmation = affirmations.randomElement() ?? Affirmation(
            text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
            category: "Confidence"
        )
        return AffirmationEntry(date: Date(), affirmation: affirmation)
    }
    
    func timeline(for configuration: AffirmationWidgetConfiguration, in context: Context) async -> Timeline<AffirmationEntry> {
        let affirmations = SharedDataService.loadAffirmations()
        let frequency = configuration.refreshFrequency ?? .everyHour
        
        var entries: [AffirmationEntry] = []
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
            let affirmation = affirmations.randomElement() ?? Affirmation(
                text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
                category: "Confidence"
            )
            entries.append(AffirmationEntry(date: entryDate, affirmation: affirmation))
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


