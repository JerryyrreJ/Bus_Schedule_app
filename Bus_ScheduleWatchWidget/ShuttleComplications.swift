//
//  ShuttleComplications.swift
//  Bus_ScheduleWatchWidget
//
//  Four watchOS complication configurations. All share the same Provider from
//  BusScheduleCore — they differ only in family + view.
//

import WidgetKit
import SwiftUI
import BusScheduleCore

struct ShuttleWatchCircular: Widget {
    let kind = "ShuttleWatchCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            WatchCircularView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(BusScheduleStrings.resource("Shuttle · Circular"))
        .description(BusScheduleStrings.resource("Watch circular complication with bus icon and next departure."))
        .supportedFamilies([.accessoryCircular])
    }
}

struct ShuttleWatchRectangular: Widget {
    let kind = "ShuttleWatchRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            WatchRectangularView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(BusScheduleStrings.resource("Shuttle · Rectangular"))
        .description(BusScheduleStrings.resource("Watch rectangular complication with route, time, and countdown."))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct ShuttleWatchInline: Widget {
    let kind = "ShuttleWatchInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            WatchInlineView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(BusScheduleStrings.resource("Shuttle · Inline"))
        .description(BusScheduleStrings.resource("Watch inline complication with single-line departure summary."))
        .supportedFamilies([.accessoryInline])
    }
}

#if os(watchOS)
struct ShuttleWatchCorner: Widget {
    let kind = "ShuttleWatchCorner"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            WatchCornerView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(BusScheduleStrings.resource("Shuttle · Corner"))
        .description(BusScheduleStrings.resource("Watch corner complication for the Infograph face."))
        .supportedFamilies([.accessoryCorner])
    }
}
#endif
