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
