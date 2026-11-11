//
//  Bus_ScheduleApp.swift
//  Bus_Schedule
//
//  Created by 卢浩然 on 2024/11/11.
//

import SwiftUI
import UserNotifications
import BusScheduleCore

private final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

@main
struct Bus_ScheduleApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = ForegroundNotificationDelegate.shared
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
