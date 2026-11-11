//
//  WatchCornerPreviews.swift
//  Bus_ScheduleWatchWidget
//

import WidgetKit
import SwiftUI
import BusScheduleCore

#if os(watchOS)
#Preview("Corner · Morning", as: .accessoryCorner) {
    ShuttleWatchCorner()
} timeline: {
    WatchPreviewFixtures.cornerMorning
}

#Preview("Corner · Return Immediately", as: .accessoryCorner) {
    ShuttleWatchCorner()
} timeline: {
    WatchPreviewFixtures.cornerReturnImmediately
}

#Preview("Corner · Last Bus", as: .accessoryCorner) {
    ShuttleWatchCorner()
} timeline: {
    WatchPreviewFixtures.cornerLastBus
}

#Preview("Corner · Service Ended", as: .accessoryCorner) {
    ShuttleWatchCorner()
} timeline: {
    WatchPreviewFixtures.cornerServiceEnded
}
#endif

#if DEBUG && os(watchOS)
#Preview("Corner · Countdown boundaries", as: .accessoryCorner) {
    ShuttleWatchCorner()
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
