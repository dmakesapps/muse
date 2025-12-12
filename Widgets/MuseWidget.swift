import WidgetKit
import SwiftUI

@main
struct MuseWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Static widgets (simple, no configuration)
        QuoteWidget()
        AffirmationWidget()
        
        // Configurable widgets (user can set refresh frequency)
        QuoteWidgetConfigurable()
        AffirmationWidgetConfigurable()
    }
}

