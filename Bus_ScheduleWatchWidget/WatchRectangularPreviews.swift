//
//  WatchRectangularPreviews.swift
//  Bus_ScheduleWatchWidget
//

import WidgetKit
import SwiftUI
import BusScheduleCore

#Preview("Rectangular · Morning", as: .accessoryRectangular) {
    ShuttleWatchRectangular()
} timeline: {
    WatchPreviewFixtures.rectangularMorning
}

#Preview("Rectangular · Return Immediately", as: .accessoryRectangular) {
    ShuttleWatchRectangular()
} timeline: {
    WatchPreviewFixtures.rectangularReturnImmediately
}

#Preview("Rectangular · Last Bus", as: .accessoryRectangular) {
    ShuttleWatchRectangular()
} timeline: {
    WatchPreviewFixtures.rectangularLastBus
}

#Preview("Rectangular · Service Ended", as: .accessoryRectangular) {
    ShuttleWatchRectangular()
} timeline: {
    WatchPreviewFixtures.rectangularServiceEnded
}

#if DEBUG
#Preview("Rectangular · Countdown boundaries", as: .accessoryRectangular) {
    ShuttleWatchRectangular()
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
