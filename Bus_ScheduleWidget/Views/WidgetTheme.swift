//
//  WidgetTheme.swift
//  Bus_ScheduleWidget
//
//  Centralized colors, route labels, and SF Symbol choices used across all
//  widget sizes. Mirrors NextBusView's accent rule (Phase II → Phase I = green,
//  Phase I → Phase II = blue) so home screen and main app stay coherent.
//

import SwiftUI

enum WidgetTheme {

    static let busSymbol = "bus.fill"

    /// Route name shown on the chip / route header. Kept English-only by
    /// product decision (matches main app's ContentView.routeLabel).
    static func routeLabel(for location: Location) -> String {
        location == .phIINewCampus ? "Phase II → Phase I" : "Phase I → Phase II"
    }

    /// Compact route label for accessoryInline (the lock-screen single-line
    /// widget) — the system aggressively truncates anything longer.
    static func compactRouteLabel(for location: Location) -> String {
        location == .phIINewCampus ? "Ph II→I" : "Ph I→II"
    }

    /// Brand accent color per direction.
    /// Matches NextBusView.accentColor.
    static func accentColor(for location: Location) -> Color {
        location == .phIINewCampus ? .green : .blue
    }

    /// Color for the countdown number in a given urgency band.
    /// Critical = red, warm = orange, normal = direction's accent color.
    static func countdownColor(for urgency: WidgetUrgency, location: Location) -> Color {
        switch urgency {
        case .normal:   return accentColor(for: location)
        case .warm:     return .orange
        case .critical: return .red
        }
    }

    /// Title weight for the big departure number. Heavier when critical so
    /// urgency survives Tinted Mode (which strips color but not weight).
    static func bigTimeWeight(for urgency: WidgetUrgency) -> Font.Weight {
        switch urgency {
        case .normal:   return .ultraLight
        case .warm:     return .thin
        case .critical: return .light
        }
    }

    /// The opposite direction of the entry's primary route.
    static func opposite(of location: Location) -> Location {
        location == .phIINewCampus ? .phIParkingLot : .phIINewCampus
    }
}
