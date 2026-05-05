//
//  Bus_ScheduleWatchApp.swift
//  Bus_ScheduleWatch
//
//  watchOS app entry. Calls SharedStore.startCloudSync() in init so the
//  override chip on the iPhone propagates to the Watch via iCloud KV.
//

import SwiftUI
import BusScheduleCore

@main
struct Bus_ScheduleWatchApp: App {
    init() {
        SharedStore.startCloudSync()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
