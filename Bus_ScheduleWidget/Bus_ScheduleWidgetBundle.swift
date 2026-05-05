//
//  Bus_ScheduleWidgetBundle.swift
//  Bus_ScheduleWidget
//
//  Created by 卢浩然 on 2026/5/5.
//
//  Entry point for the Widget Extension. Registers four widget kinds:
//    • Home-screen: small + medium (one Widget definition, branches by family)
//    • Lock Screen: rectangular, circular, inline (three definitions)
//

import WidgetKit
import SwiftUI

@main
struct Bus_ScheduleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShuttleHomeWidget()
        ShuttleLockRectangularWidget()
        ShuttleLockCircularWidget()
        ShuttleLockInlineWidget()
    }
}
