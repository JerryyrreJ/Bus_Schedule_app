//
//  ContentView.swift
//  Bus_Schedule
//
//  Created by 卢浩然 on 2024/11/11.
//

import SwiftUI
import UIKit
import BusScheduleCore

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var location: Location = SharedStore.readPrimaryRoute()
    @State private var dayType: DayType = DayType.effective().dayType
    @State private var isManualOverride: Bool = DayType.effective().isManualOverride
    @StateObject private var reminderScheduler = LocalBusReminderScheduler()

    private var locationBinding: Binding<Location> {
        Binding(
            get: { location },
            set: { newValue in
                location = newValue
                SharedStore.writePrimaryRoute(newValue)
            }
        )
    }

    private var dayTypeBinding: Binding<DayType> {
        Binding(
            get: { dayType },
            set: { newValue in
                let auto = DayType.automatic(for: Date())
                dayType = newValue
                isManualOverride = (newValue != auto)
                // SharedStore writes to App Group UserDefaults and republishes
                // the latest state to the paired Watch.
                SharedStore.writeOverride(newValue == auto ? nil : newValue)
            }
        )
    }

    private var routeLabel: String {
        WidgetTheme.routeLabel(for: location)
    }

    var body: some View {
        GeometryReader { viewport in
            let isCompact = viewport.size.height < 640
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header(isCompact: isCompact)
                        .padding(.top, isCompact ? 10 : 20)
                        .padding(.horizontal, isCompact ? 20 : 24)

                    LocationToggleView(location: locationBinding, isCompact: isCompact)
                        .padding(.top, isCompact ? 12 : 20)
                        .padding(.horizontal, isCompact ? 16 : 20)

                    NextBusView(
                        location: location,
                        dayType: dayType,
                        isManualOverride: isManualOverride,
                        isCompact: isCompact
                    )
                    .padding(.top, isCompact ? 18 : 32)
                    .padding(.horizontal, isCompact ? 20 : 24)

                    Spacer(minLength: isCompact ? 12 : 20)

                    BusReminderButton(
                        location: location,
                        dayType: dayType,
                        scheduler: reminderScheduler,
                        isCompact: isCompact
                    )
                    .padding(.horizontal, isCompact ? 16 : 20)
                    .padding(.bottom, isCompact ? 8 : 12)

                    DayTypeToggleView(
                        dayType: dayTypeBinding,
                        isManualOverride: isManualOverride,
                        isCompact: isCompact
                    )
                    .padding(.horizontal, isCompact ? 16 : 20)
                    .padding(.bottom, isCompact ? 12 : 20)
                }
                .frame(maxWidth: .infinity, minHeight: viewport.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            SharedStore.startWatchSync()
            applyRoutePreference()
            applyEffectiveDayType()
            Task { await reminderScheduler.refresh() }
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            SharedStore.startWatchSync()
            applyRoutePreference()
            applyEffectiveDayType()
            Task { await reminderScheduler.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification).receive(on: RunLoop.main)) { _ in
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .primaryRouteDidChange).receive(on: RunLoop.main)) { _ in
            applyRoutePreference()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dayTypeOverrideDidChange).receive(on: RunLoop.main)) { _ in
            // Fired when a synced override arrives from the counterpart device.
            // Re-read the effective day type from SharedStore.
            applyEffectiveDayType()
        }
    }

    private func header(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(BusScheduleStrings.campusShuttle)
                .font(.system(size: isCompact ? 12 : 13, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(routeLabel)
                .font(.system(size: isCompact ? 22 : 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .animation(.easeInOut(duration: 0.25), value: location)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    /// Resolve the effective day type from (persisted override) → (auto for today).
    /// Self-heal: if the override now matches what auto-detection would return,
    /// clear it so the chip naturally flips back to "Auto · …".
    private func applyEffectiveDayType(referenceDate: Date = Date()) {
        SharedStore.selfHealOverride(for: referenceDate)
        let resolved = DayType.effective(for: referenceDate)
        dayType = resolved.dayType
        isManualOverride = resolved.isManualOverride
    }

    private func applyRoutePreference() {
        location = SharedStore.readPrimaryRoute()
    }
}

#Preview {
    ContentView()
}
