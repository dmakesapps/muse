import WidgetKit
import SwiftUI

struct AffirmationWidget: Widget {
    let kind: String = "AffirmationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AffirmationProvider()) { entry in
            AffirmationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Affirmation Widget")
        .description("Display your saved affirmations on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled() // Remove default margins
    }
}

struct AffirmationProvider: TimelineProvider {
    // Default refresh: every hour
    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(
            date: Date(),
            affirmation: Affirmation(
                text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
                category: "Confidence"
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> ()) {
        let affirmations = SharedDataService.loadAffirmations()
        // Only use saved affirmations
        let affirmation = affirmations.randomElement() ?? Affirmation(
            text: "Save affirmations in the app to see them here.",
            category: "Tip"
        )
        let entry = AffirmationEntry(date: Date(), affirmation: affirmation)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> ()) {
        let affirmations = SharedDataService.loadAffirmations()
        
        // Only use saved affirmations - don't show defaults if user has saved items
        guard !affirmations.isEmpty else {
            // If no saved affirmations, create empty timeline (widget will show placeholder)
            let timeline = Timeline<AffirmationEntry>(entries: [], policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date())!))
            completion(timeline)
            return
        }
        
        var entries: [AffirmationEntry] = []
        let currentDate = Date()
        
        // Create entries for the next 24 hours, refreshing every hour
        // Shuffle affirmations to ensure variety
        let shuffledAffirmations = affirmations.shuffled()
        var affirmationIndex = 0
        
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            // Cycle through shuffled affirmations
            let affirmation = shuffledAffirmations[affirmationIndex % shuffledAffirmations.count]
            affirmationIndex += 1
            entries.append(AffirmationEntry(date: entryDate, affirmation: affirmation))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct AffirmationEntry: TimelineEntry {
    let date: Date
    let affirmation: Affirmation
}

struct AffirmationWidgetEntryView: View {
    var entry: AffirmationProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // Full background - fills entire widget space
            Color.museDeepNavy
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: spacing) {
                // Category badge
                Text(entry.affirmation.category.uppercased())
                    .font(.system(size: categoryFontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.museGradientStart)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.museGradientStart.opacity(0.2), Color.museGradientEnd.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                
                // Affirmation text
                Text(entry.affirmation.text)
                    .font(.system(size: affirmationFontSize, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(affirmationLineLimit)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                
                Spacer()
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
    
    private var affirmationFontSize: CGFloat {
        switch family {
        case .systemSmall: return 14
        case .systemMedium: return 16
        case .systemLarge: return 18
        default: return 16
        }
    }
    
    private var affirmationLineLimit: Int? {
        switch family {
        case .systemSmall: return 5
        case .systemMedium: return 7
        case .systemLarge: return nil
        default: return 7
        }
    }
}

#Preview(as: .systemSmall) {
    AffirmationWidget()
} timeline: {
    AffirmationEntry(
        date: Date(),
        affirmation: Affirmation(
            text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
            category: "Confidence"
        )
    )
}

