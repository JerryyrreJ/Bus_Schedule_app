//
//  WatchCircularPreviews.swift
//  Bus_ScheduleWatchWidget
//

import WidgetKit
import SwiftUI
import BusScheduleCore

#Preview("Circular · Morning", as: .accessoryCircular) {
    ShuttleWatchCircular()
} timeline: {
    WatchPreviewFixtures.circularMorning
}

#Preview("Circular · Before First", as: .accessoryCircular) {
    ShuttleWatchCircular()
} timeline: {
    WatchPreviewFixtures.circularBeforeFirstDeparture
}

#Preview("Circular · Return Immediately", as: .accessoryCircular) {
    ShuttleWatchCircular()
} timeline: {
    WatchPreviewFixtures.circularReturnImmediately
}

#Preview("Circular · Last Bus", as: .accessoryCircular) {
    ShuttleWatchCircular()
} timeline: {
    WatchPreviewFixtures.circularLastBus
}

#Preview("Circular · Service Ended", as: .accessoryCircular) {
    ShuttleWatchCircular()
} timeline: {
    WatchPreviewFixtures.circularServiceEnded
}

#if DEBUG
#Preview("Circular · Countdown boundaries", as: .accessoryCircular) {
    ShuttleWatchCircular()
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
