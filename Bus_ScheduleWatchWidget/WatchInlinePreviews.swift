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
