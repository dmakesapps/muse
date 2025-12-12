import WidgetKit
import SwiftUI

struct AffirmationWidget: Widget {
    let kind: String = "AffirmationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AffirmationProvider()) { entry in
            AffirmationWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Affirmation Widget")
        .description("Display your saved affirmations on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
        let affirmation = affirmations.randomElement() ?? Affirmation(
            text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
            category: "Confidence"
        )
        let entry = AffirmationEntry(date: Date(), affirmation: affirmation)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> ()) {
        let affirmations = SharedDataService.loadAffirmations()
        
        var entries: [AffirmationEntry] = []
        let currentDate = Date()
        
        // Create entries for the next 24 hours, refreshing every hour
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let affirmation = affirmations.randomElement() ?? Affirmation(
                text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
                category: "Confidence"
            )
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
    
    var body: some View {
        ZStack {
            // Background with glassmorphism effect
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .background(.ultraThinMaterial)
            
            VStack(alignment: .leading, spacing: 12) {
                // Category badge
                Text(entry.affirmation.category.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(16)
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

