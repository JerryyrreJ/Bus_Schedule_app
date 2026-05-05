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

struct OverrideChip: View {
    let dayType: DayType
    let isManualOverride: Bool

    var body: some View {
        Button(intent: ToggleDayTypeIntent()) {
            HStack(spacing: 5) {
                Text(prefix)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .opacity(0.65)
                Text("· \(label)")
                    .font(.system(size: 11, weight: .semibold))
                if isManualOverride {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 8, weight: .bold))
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(isManualOverride ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .foregroundStyle(isManualOverride ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private var prefix: String { isManualOverride ? "Manual" : "Auto" }

    private var label: String {
        switch dayType {
        case .weekday:         return "Weekday"
        case .saturday:        return "Saturday"
        case .sundayOrHoliday: return "Holiday"
        }
    }
}
