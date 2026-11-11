//
//  OverrideChip.swift
//  Bus_ScheduleWidget
//
//  The schedule-override chip rendered in the medium widget. Tappable via
//  AppIntent (iOS 17+) — invoking ToggleDayTypeIntent cycles the override
//  state Auto → Manual → Auto, then triggers WidgetKit reload.
//

import SwiftUI
import AppIntents
import BusScheduleCore

struct OverrideChip: View {
    let dayType: DayType
    let isManualOverride: Bool

    var body: some View {
        Button(intent: ToggleDayTypeIntent()) {
            HStack(spacing: 4) {
                Text(prefix)
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .opacity(0.65)
                Text("· \(label)")
                    .font(.system(size: 10.5, weight: .semibold))
                if isManualOverride {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 8, weight: .bold))
                        .opacity(0.7)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, isManualOverride ? 7 : 2)
            .padding(.vertical, 2.5)
            .background(
                Capsule().fill(isManualOverride ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .foregroundStyle(isManualOverride ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private var prefix: String { isManualOverride ? BusScheduleStrings.manual : BusScheduleStrings.auto }

    private var label: String {
        switch dayType {
        case .weekday:         return BusScheduleStrings.weekday
        case .saturday:        return BusScheduleStrings.saturday
        case .sundayOrHoliday: return BusScheduleStrings.holiday
        }
    }
}
