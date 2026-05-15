//
//  ShuttleHomeIntent.swift
//  Bus_ScheduleWidget
//
//  WidgetConfigurationIntent exposed in the iOS Edit Widget sheet. Currently
//  only carries the visual style choice; future per-instance options
//  (default direction, footer density, etc.) can hang off this same intent.
//

import AppIntents
import WidgetKit

struct ShuttleHomeIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Campus Shuttle"
    static var description = IntentDescription("Choose how the widget is rendered.")

    @Parameter(title: "Style", default: .card)
    var style: WidgetStyle
}
