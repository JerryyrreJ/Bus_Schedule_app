import SwiftUI
import WidgetKit
import BusScheduleCore

#if DEBUG && os(iOS)
#Preview("Small · Countdown boundaries", as: .systemSmall) {
    ShuttleHomeWidget()
} timeline: {
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.now), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.seconds), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.oneMinute), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.nineMinutes), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.tenMinutes), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.fiftyNineMinutes), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.oneHour), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.hourAndFortyFive), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.nineHours), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.tenHours), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.longest), style: .card)
}

#Preview("Medium Card · Countdown boundaries", as: .systemMedium) {
    ShuttleHomeWidget()
} timeline: {
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.now), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.seconds), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.oneMinute), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.nineMinutes), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.tenMinutes), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.fiftyNineMinutes), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.oneHour), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.hourAndFortyFive), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.nineHours), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.tenHours), style: .card)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.longest), style: .card)
}

#Preview("Medium Minimal · Countdown boundaries", as: .systemMedium) {
    ShuttleHomeWidget()
} timeline: {
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.now), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.seconds), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.oneMinute), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.nineMinutes), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.tenMinutes), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.fiftyNineMinutes), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.oneHour), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.hourAndFortyFive), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.nineHours), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.tenHours), style: .minimal)
    StyledShuttleEntry(base: WidgetLayoutPreview.entry(.longest), style: .minimal)
}

#Preview("Lock Rectangular · Countdown boundaries", as: .accessoryRectangular) {
    ShuttleLockRectangularWidget()
} timeline: {
    WidgetLayoutPreview.entry(.now)
    WidgetLayoutPreview.entry(.seconds)
    WidgetLayoutPreview.entry(.oneMinute)
    WidgetLayoutPreview.entry(.nineMinutes)
    WidgetLayoutPreview.entry(.tenMinutes)
    WidgetLayoutPreview.entry(.fiftyNineMinutes)
    WidgetLayoutPreview.entry(.oneHour)
    WidgetLayoutPreview.entry(.hourAndFortyFive)
    WidgetLayoutPreview.entry(.nineHours)
    WidgetLayoutPreview.entry(.tenHours)
    WidgetLayoutPreview.entry(.longest)
}

#Preview("Lock Circular · Countdown boundaries", as: .accessoryCircular) {
    ShuttleLockCircularWidget()
} timeline: {
    WidgetLayoutPreview.entry(.now)
    WidgetLayoutPreview.entry(.seconds)
    WidgetLayoutPreview.entry(.oneMinute)
    WidgetLayoutPreview.entry(.nineMinutes)
    WidgetLayoutPreview.entry(.tenMinutes)
    WidgetLayoutPreview.entry(.fiftyNineMinutes)
    WidgetLayoutPreview.entry(.oneHour)
    WidgetLayoutPreview.entry(.hourAndFortyFive)
    WidgetLayoutPreview.entry(.nineHours)
    WidgetLayoutPreview.entry(.tenHours)
    WidgetLayoutPreview.entry(.longest)
}

#Preview("Lock Inline · Countdown boundaries", as: .accessoryInline) {
    ShuttleLockInlineWidget()
} timeline: {
    WidgetLayoutPreview.entry(.now)
    WidgetLayoutPreview.entry(.seconds)
    WidgetLayoutPreview.entry(.oneMinute)
    WidgetLayoutPreview.entry(.nineMinutes)
    WidgetLayoutPreview.entry(.tenMinutes)
    WidgetLayoutPreview.entry(.fiftyNineMinutes)
    WidgetLayoutPreview.entry(.oneHour)
    WidgetLayoutPreview.entry(.hourAndFortyFive)
    WidgetLayoutPreview.entry(.nineHours)
    WidgetLayoutPreview.entry(.tenHours)
    WidgetLayoutPreview.entry(.longest)
}

#endif
