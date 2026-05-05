//
//  ContentView.swift
//  Bus_Schedule
//
//  Created by 卢浩然 on 2024/11/11.
//

import SwiftUI
import UIKit
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var location: Location = .phIINewCampus
    @State private var dayType: DayType = .weekday

    /// Persisted manual override of the day type. Empty string means "follow auto".
    /// Stored in the App Group suite so the main app and the Widget extension
    /// share the same value.
    @AppStorage("dayTypeOverride", store: SharedStore.defaults)
    private var dayTypeOverrideRaw: String = ""

    private var dayTypeBinding: Binding<DayType> {
        Binding(
            get: { dayType },
            set: { newValue in
                let auto = DayType.automatic(for: Date())
                dayType = newValue
                // If the user picks the auto-detected value, clear the override so
                // the chip flips back to "Auto · …". Otherwise persist the manual
                // selection so it survives across launches.
                dayTypeOverrideRaw = (newValue == auto) ? "" : newValue.rawValue
                // Tell WidgetKit to refresh: a chip change should propagate to the
                // home/lock-screen widgets immediately.
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    }

    private var routeLabel: String {
        location == .phIINewCampus ? "Phase II → Phase I" : "Phase I → Phase II"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 24)
                .padding(.horizontal, 24)

            LocationToggleView(location: $location)
                .padding(.top, 24)
                .padding(.horizontal, 20)

            NextBusView(location: location, dayType: dayType)
                .padding(.top, 40)
                .padding(.horizontal, 24)

            Spacer(minLength: 24)

            DayTypeToggleView(dayType: dayTypeBinding)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            applyEffectiveDayType()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            applyEffectiveDayType()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Campus Shuttle")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Text(routeLabel)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .animation(.easeInOut(duration: 0.25), value: location)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Resolve the effective day type from (persisted override) → (auto for today).
    /// Self-heal: if the override now matches what auto-detection would return,
    /// clear it so the chip naturally flips back to "Auto · …".
    private func applyEffectiveDayType(referenceDate: Date = Date()) {
        SharedStore.selfHealOverride(for: referenceDate)
        let resolved = DayType.effective(for: referenceDate)
        dayType = resolved.dayType
    }

    private static func automaticDayType(for date: Date) -> DayType {
        DayType.automatic(for: date)
    }
}

#Preview {
    ContentView()
}
