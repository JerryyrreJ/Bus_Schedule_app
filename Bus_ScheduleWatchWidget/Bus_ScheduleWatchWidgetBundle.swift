//
//  Bus_ScheduleWatchWidgetBundle.swift
//  Bus_ScheduleWatchWidget
//
//  Created by 卢浩然 on 2026/5/5.
//
//  watchOS complication bundle. Registers four families: circular,
//  rectangular, inline, and corner (corner is watchOS-only).
//

import WidgetKit
import SwiftUI

@main
struct Bus_ScheduleWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShuttleWatchCircular()
        ShuttleWatchRectangular()
        ShuttleWatchInline()
        ShuttleWatchCorner()
    }
}
