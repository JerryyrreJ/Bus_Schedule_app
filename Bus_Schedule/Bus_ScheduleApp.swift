//
//  Bus_ScheduleApp.swift
//  Bus_Schedule
//
//  Created by 卢浩然 on 2024/11/11.
//

import SwiftUI
import BusScheduleCore

@main
struct Bus_ScheduleApp: App {
    init() {
        // Activate WatchConnectivity once per process launch so the override
        // stays in sync with the paired Apple Watch.
        SharedStore.startWatchSync()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
