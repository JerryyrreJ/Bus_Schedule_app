//
//  WatchInlinePreviews.swift
//  Bus_ScheduleWatchWidget
//

import WidgetKit
import SwiftUI
import BusScheduleCore

#Preview("Inline · Morning", as: .accessoryInline) {
    ShuttleWatchInline()
} timeline: {
    WatchPreviewFixtures.inlineMorning
}

#Preview("Inline · Return Immediately", as: .accessoryInline) {
    ShuttleWatchInline()
} timeline: {
    WatchPreviewFixtures.inlineReturnImmediately
}

#Preview("Inline · Last Bus", as: .accessoryInline) {
    ShuttleWatchInline()
} timeline: {
    WatchPreviewFixtures.inlineLastBus
}

#Preview("Inline · Service Ended", as: .accessoryInline) {
    ShuttleWatchInline()
} timeline: {
    WatchPreviewFixtures.inlineServiceEnded
}

#if DEBUG
#Preview("Inline · Countdown boundaries", as: .accessoryInline) {
    ShuttleWatchInline()
} timeline: {
    WidgetLayoutPreview.entry(.now)
    WidgetLayoutPreview.entry(.seconds)
    WidgetLayoutPreview.entry(.oneMinute)
    WidgetLayoutPreview.entry(.nineMinutes)
    WidgetLayoutPreview.entry(.tenMinutes)
    WidgetLayoutPreview.entry(.fiftyNineMinutes)
    WidgetLayoutPreview.entry(.oneHour)
    WidgetLayoutPreview.entry(.hourAndFortyFive)
    WidgetLayoutPreview.entry(.nineHours)
    WidgetLayoutPreview.entry(.tenHours)
    WidgetLayoutPreview.entry(.longest)
}
#endif
