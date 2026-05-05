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
        // Subscribe to iCloud KV remote changes once per process launch so the
        // override chip stays in sync between iPhone and Apple Watch.
        SharedStore.startCloudSync()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
