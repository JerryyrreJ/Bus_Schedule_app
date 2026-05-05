//
//  Bus_ScheduleWatchApp.swift
//  Bus_ScheduleWatch
//
//  watchOS app entry. Activates WatchConnectivity so the paired iPhone can
//  propagate its latest override into the watch's local shared store.
//

import SwiftUI
import BusScheduleCore

@main
struct Bus_ScheduleWatchApp: App {
    init() {
        SharedStore.startWatchSync()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
