//
//  WidgetStyle.swift
//  Bus_ScheduleWidget
//
//  User-facing style choice for the home-screen widget, surfaced through
//  the Edit Widget configuration sheet.
//

import AppIntents

enum WidgetStyle: String, AppEnum {
    case card
    case minimal

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Style"

    static let caseDisplayRepresentations: [WidgetStyle: DisplayRepresentation] = [
        .card: DisplayRepresentation(
            title: "Card",
            subtitle: "Nested rounded cards"
        ),
        .minimal: DisplayRepresentation(
            title: "Minimal",
            subtitle: "Whitespace + hairlines"
        )
    ]
}
