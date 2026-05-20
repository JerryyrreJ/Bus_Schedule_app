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
        .configurationDisplayName(LocalizedStringResource(stringLiteral: BusScheduleStrings.shuttleCircular))
        .description(LocalizedStringResource(stringLiteral: BusScheduleStrings.watchCircularDescription))
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
        .configurationDisplayName(LocalizedStringResource(stringLiteral: BusScheduleStrings.shuttleRectangular))
        .description(LocalizedStringResource(stringLiteral: BusScheduleStrings.watchRectangularDescription))
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
        .configurationDisplayName(LocalizedStringResource(stringLiteral: BusScheduleStrings.shuttleInline))
        .description(LocalizedStringResource(stringLiteral: BusScheduleStrings.watchInlineDescription))
        .supportedFamilies([.accessoryInline])
    }
}

struct ShuttleWatchCorner: Widget {
    let kind = "ShuttleWatchCorner"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            WatchCornerView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource(stringLiteral: BusScheduleStrings.shuttleCorner))
        .description(LocalizedStringResource(stringLiteral: BusScheduleStrings.watchCornerDescription))
        .supportedFamilies([.accessoryCorner])
    }
}
