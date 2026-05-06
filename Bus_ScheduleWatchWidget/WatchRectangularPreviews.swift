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
