//
//  StopSunWidgetLiveActivity.swift
//  StopSunWidget
//
//  Created by taeni on 2/23/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StopSunWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StopSunWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StopSunWidgetAttributes.self) { context in
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

extension StopSunWidgetAttributes {
    fileprivate static var preview: StopSunWidgetAttributes {
        StopSunWidgetAttributes(name: "World")
    }
}

extension StopSunWidgetAttributes.ContentState {
    fileprivate static var smiley: StopSunWidgetAttributes.ContentState {
        StopSunWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StopSunWidgetAttributes.ContentState {
         StopSunWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StopSunWidgetAttributes.preview) {
   StopSunWidgetLiveActivity()
} contentStates: {
    StopSunWidgetAttributes.ContentState.smiley
    StopSunWidgetAttributes.ContentState.starEyes
}
