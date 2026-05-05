//
//  WidgetTheme.swift
//  BusScheduleCore
//
//  Centralized colors, route labels, and SF Symbol choices used across
//  iPhone widget views, watchOS app views, and watchOS complications.
//

import SwiftUI

public enum WidgetTheme {

    public static let busSymbol = "bus.fill"

    public static func routeLabel(for location: Location) -> String {
        location == .phIINewCampus ? "Phase II → Phase I" : "Phase I → Phase II"
    }

    /// Compressed label for accessoryInline / corner / circular complications.
    public static func compactRouteLabel(for location: Location) -> String {
        location == .phIINewCampus ? "Ph II→I" : "Ph I→II"
    }

    /// Direction-coded accent. Matches NextBusView.accentColor.
    public static func accentColor(for location: Location) -> Color {
        location == .phIINewCampus ? .green : .blue
    }

    public static func countdownColor(for urgency: WidgetUrgency, location: Location) -> Color {
        switch urgency {
        case .normal:   return accentColor(for: location)
        case .warm:     return .orange
        case .critical: return .red
        }
    }

    /// Heavier weight when critical — survives Tinted Mode (which strips color
    /// but not weight) so the "leave now" signal still reads.
    public static func bigTimeWeight(for urgency: WidgetUrgency) -> Font.Weight {
        switch urgency {
        case .normal:   return .ultraLight
        case .warm:     return .thin
        case .critical: return .light
        }
    }

    public static func opposite(of location: Location) -> Location {
        location == .phIINewCampus ? .phIParkingLot : .phIINewCampus
    }
}
