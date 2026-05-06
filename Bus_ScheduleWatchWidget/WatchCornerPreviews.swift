//
//  WatchCornerPreviews.swift
//  Bus_ScheduleWatchWidget
//

import WidgetKit
import SwiftUI
import BusScheduleCore

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
