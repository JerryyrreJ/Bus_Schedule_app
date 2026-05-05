//
//  ContentView.swift
//  Bus_Schedule
//
//  Created by 卢浩然 on 2024/11/11.
//

import SwiftUI
import UIKit
import WidgetKit
import BusScheduleCore

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var location: Location = .phIINewCampus
    @State private var dayType: DayType = .weekday

    private var dayTypeBinding: Binding<DayType> {
        Binding(
            get: { dayType },
            set: { newValue in
                let auto = DayType.automatic(for: Date())
                dayType = newValue
                // SharedStore writes to App Group UserDefaults and republishes
                // the latest state to the paired Watch.
                SharedStore.writeOverride(newValue == auto ? nil : newValue)
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
        .onReceive(NotificationCenter.default.publisher(for: .dayTypeOverrideDidChange)) { _ in
            // Fired when a synced override arrives from the counterpart device.
            // Re-read the effective day type from SharedStore.
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
        dayType = DayType.effective(for: referenceDate).dayType
    }
}

#Preview {
    ContentView()
}
