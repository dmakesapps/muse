//
//  MuseWidgetsExtensionLiveActivity.swift
//  MuseWidgetsExtension
//
//  Created by Davis on 12/13/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MuseWidgetsExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MuseWidgetsExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MuseWidgetsExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MuseWidgetsExtensionAttributes {
    fileprivate static var preview: MuseWidgetsExtensionAttributes {
        MuseWidgetsExtensionAttributes(name: "World")
    }
}

extension MuseWidgetsExtensionAttributes.ContentState {
    fileprivate static var smiley: MuseWidgetsExtensionAttributes.ContentState {
        MuseWidgetsExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MuseWidgetsExtensionAttributes.ContentState {
         MuseWidgetsExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MuseWidgetsExtensionAttributes.preview) {
   MuseWidgetsExtensionLiveActivity()
} contentStates: {
    MuseWidgetsExtensionAttributes.ContentState.smiley
    MuseWidgetsExtensionAttributes.ContentState.starEyes
}
