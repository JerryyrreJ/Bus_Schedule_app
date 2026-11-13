import SwiftUI
import BusScheduleCore

/// Right-page / companion departure board designed for iPhone Duo's unfolded
/// display and wide regular windows:
///   1. Live opposite-campus card with one-tap primary route swap
///   2. Paired Phase II ↔ Phase I timetable with Remaining / All filter
struct DuoCompanionBoard: View {
    @Binding var location: Location
    let dayType: DayType
    var isManualOverride: Bool = false
    var expandsVertically: Bool = true
    var referenceDateOverride: Date? = nil

    var body: some View {
        if let referenceDateOverride {
            content(for: referenceDateOverride)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(for: context.date)
            }
        }
    }

    private func content(for referenceDate: Date) -> some View {
        VStack(spacing: 14) {
            OppositeRouteLiveCard(
                location: $location,
                dayType: dayType,
                isManualOverride: isManualOverride,
                referenceDate: referenceDate
            )

            PairedTimetableCard(
                location: $location,
                dayType: dayType,
                expandsVertically: expandsVertically,
                referenceDate: referenceDate
            )
        }
        .frame(maxWidth: .infinity, maxHeight: expandsVertically ? .infinity : nil, alignment: .top)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

// MARK: - Hinge-Safe Spine Divider

struct HingeSpineDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color.primary.opacity(0.0), location: 0.0),
                        .init(color: Color.primary.opacity(0.11), location: 0.14),
                        .init(color: Color.primary.opacity(0.11), location: 0.86),
                        .init(color: Color.primary.opacity(0.0), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1)
            .padding(.vertical, 12)
            .frame(width: 36)
            .accessibilityHidden(true)
    }
}

// MARK: - Opposite Campus Live Card

struct OppositeRouteLiveCard: View {
    @Binding var location: Location
    let dayType: DayType
    var isManualOverride: Bool = false
    var isCompact: Bool = false
    let referenceDate: Date

    private var oppositeLocation: Location {
        WidgetTheme.opposite(of: location)
    }

    private var accentColor: Color {
        WidgetTheme.accentColor(for: oppositeLocation)
    }

    var body: some View {
        let currentSeconds = Schedule.secondsFromMidnight(for: referenceDate)
        let state = Schedule.nextDepartureState(
            for: oppositeLocation,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        )

        Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                location = oppositeLocation
            }
        } label: {
            HStack(spacing: 12) {
                Capsule()
                    .fill(accentColor)
                    .frame(width: 3.5)
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
                    headerRow

                    bodyRow(state: state, currentSeconds: currentSeconds)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, isCompact ? 12 : 15)
            .padding(.vertical, isCompact ? 10 : 13)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var headerRow: some View {
        HStack(spacing: 6) {
            Text(BusScheduleStrings.returnRoute)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("·")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)

            Text(WidgetTheme.routeLabel(for: oppositeLocation))
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 9.5, weight: .bold))
                Text(BusScheduleStrings.swap)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(accentColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.13))
            )
        }
    }

    @ViewBuilder
    private func bodyRow(state: NextDepartureState, currentSeconds: Int) -> some View {
        switch state {
        case let .scheduled(time, departureSeconds):
            let remaining = Schedule.secondsRemaining(until: departureSeconds, from: currentSeconds)
            let urgency = WidgetUrgency.from(secondsRemaining: remaining)
            let upcoming = Schedule.upcomingDepartures(
                for: oppositeLocation,
                dayType: dayType,
                currentSecondsFromMidnight: currentSeconds,
                limit: 2
            )

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(time)
                    .font(.system(size: isCompact ? 26 : 32, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .kerning(-1)
                    .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(detailedCountdown(remaining: remaining))
                    .font(.system(size: isCompact ? 13.5 : 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WidgetTheme.countdownColor(for: urgency, location: oppositeLocation))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 6)

                if !upcoming.isEmpty {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(BusScheduleStrings.then)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1.0)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(upcoming.joined(separator: " · "))
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }

        case .returnImmediately:
            let deadline = Schedule.returnImmediatelyDeadline(
                dayType: dayType,
                currentSecondsFromMidnight: currentSeconds
            )

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.green)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.green.opacity(0.15)))

                        Text(BusScheduleStrings.returnImmediately)
                            .font(.system(size: isCompact ? 18 : 21, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Text(BusScheduleStrings.continuousShuttleShort)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 6)

                if let deadline {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(BusScheduleStrings.untilUpper)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1.0)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(deadline)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
            }

        case .noMoreBuses:
            let nextDay = Schedule.nextServiceDay(
                after: referenceDate,
                currentDayType: dayType,
                isManualOverride: isManualOverride
            )
            let tomorrowStart = Schedule.firstServiceStart(
                for: oppositeLocation,
                dayType: nextDay.dayType
            )
            let lastToday = Schedule.lastDeparture(for: oppositeLocation, dayType: dayType)

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(BusScheduleStrings.serviceEnded)
                        .font(.system(size: isCompact ? 15 : 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let lastToday {
                        Text(BusScheduleStrings.lastTodayWas(lastToday))
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 6)

                if let tomorrowStart {
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(spacing: 3) {
                            Text(BusScheduleStrings.firstTomorrow)
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(0.8)
                                .foregroundStyle(.secondary)
                            if case .returnImmediately = tomorrowStart {
                                Text("· \(BusScheduleStrings.loop)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .lineLimit(1)

                        Text(tomorrowStart.compactDisplayText)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func detailedCountdown(remaining: Int) -> String {
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        if remaining < 3600 {
            return String(format: "%dm %02ds", minutes, seconds)
        }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}

// MARK: - Paired Timetable Booklet Card

struct PairedTimetableCard: View {
    @Binding var location: Location
    let dayType: DayType
    var expandsVertically: Bool = true
    let referenceDate: Date

    @State private var showAllRuns: Bool = false

    private var primaryAccent: Color {
        WidgetTheme.accentColor(for: location)
    }

    var body: some View {
        let currentSeconds = Schedule.secondsFromMidnight(for: referenceDate)
        let allRows = Schedule.timetableRows(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        )
        let remainingCount = Schedule.remainingRunCount(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        )
        let upcomingRows = allRows.filter { $0.status != .past }
        let isShowingAll = showAllRuns || upcomingRows.isEmpty
        let visibleRows = isShowingAll ? allRows : upcomingRows
        let highlightedID = allRows.first(where: \.isHighlighted)?.id

        VStack(spacing: 0) {
            cardHeader(
                remainingCount: remainingCount,
                totalCount: allRows.count,
                hasUpcoming: !upcomingRows.isEmpty
            )
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 9)

            columnHeaderBar
                .padding(.horizontal, 14)
                .padding(.bottom, 7)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)

            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(visibleRows) { row in
                            timetableRowView(row: row, isFinalRow: row.id == allRows.last?.id)
                                .id(row.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: expandsVertically ? 180 : 250,
                    maxHeight: expandsVertically ? .infinity : 290
                )
                .onChange(of: showAllRuns) { _, newValue in
                    guard newValue, let highlightedID else { return }
                    withAnimation(.easeInOut(duration: 0.28)) {
                        scrollProxy.scrollTo(highlightedID, anchor: .center)
                    }
                }
                .onChange(of: location) { _, _ in
                    guard isShowingAll, let highlightedID else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scrollProxy.scrollTo(highlightedID, anchor: .center)
                    }
                }
                .onChange(of: dayType) { _, _ in
                    guard isShowingAll, let highlightedID else { return }
                    scrollProxy.scrollTo(highlightedID, anchor: .center)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func cardHeader(remainingCount: Int, totalCount: Int, hasUpcoming: Bool) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Text(BusScheduleStrings.todaysSchedule)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("·")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)

                Text(
                    remainingCount > 0 && !showAllRuns
                        ? BusScheduleStrings.runsLeft(remainingCount)
                        : BusScheduleStrings.totalRuns(totalCount)
                )
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .minimumScaleFactor(0.8)

            Spacer(minLength: 6)

            if hasUpcoming {
                filterToggle
            }
        }
    }

    private var filterToggle: some View {
        HStack(spacing: 2) {
            filterChip(title: BusScheduleStrings.remaining, isSelected: !showAllRuns) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    showAllRuns = false
                }
            }

            filterChip(title: BusScheduleStrings.all, isSelected: showAllRuns) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    showAllRuns = true
                }
            }
        }
        .padding(2)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.07))
        )
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 3.5)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private var columnHeaderBar: some View {
        HStack(spacing: 0) {
            columnHeaderButton(
                title: BusScheduleStrings.phaseII,
                target: .phIINewCampus,
                dotColor: .green
            )

            columnHeaderButton(
                title: BusScheduleStrings.phaseI,
                target: .phIParkingLot,
                dotColor: .blue
            )

            Spacer(minLength: 0)
                .frame(width: 66)
        }
    }

    private func columnHeaderButton(title: String, target: Location, dotColor: Color) -> some View {
        let isActive = location == target
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                location = target
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(dotColor.opacity(isActive ? 1.0 : 0.45))
                    .frame(width: 6, height: 6)

                Text(title)
                    .font(.system(size: 11.5, weight: isActive ? .bold : .semibold))
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func timetableRowView(row: TimetableRow, isFinalRow: Bool) -> some View {
        let isHighlighted = row.isHighlighted
        let rowAccent: Color = row.status == .activeLoop ? .green : primaryAccent

        return HStack(spacing: 0) {
            // Phase II Departure Column
            HStack(spacing: 6) {
                Capsule()
                    .fill(isHighlighted ? rowAccent : Color.clear)
                    .frame(width: 3, height: 16)

                Text(row.phIITime ?? "—")
                    .font(.system(
                        size: 15,
                        weight: isHighlighted && location == .phIINewCampus ? .bold : .medium,
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .foregroundStyle(
                        cellForeground(
                            isPast: row.isPhIIPast,
                            isPrimaryColumn: location == .phIINewCampus,
                            isHighlighted: isHighlighted
                        )
                    )
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Phase I Departure / Loop Column
            Group {
                if row.isPhIReturnImmediately {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                        Text(BusScheduleStrings.loop)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        row.isPhIPast && !isHighlighted
                            ? Color.secondary.opacity(0.55)
                            : Color.green
                    )
                } else {
                    Text(row.phITime ?? "—")
                        .font(.system(
                            size: 15,
                            weight: isHighlighted && location == .phIParkingLot ? .bold : .medium,
                            design: .rounded
                        ))
                        .monospacedDigit()
                        .foregroundStyle(
                            cellForeground(
                                isPast: row.isPhIPast || row.phITime == nil,
                                isPrimaryColumn: location == .phIParkingLot,
                                isHighlighted: isHighlighted
                            )
                        )
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Trailing Status Badge Slot
            Group {
                switch row.status {
                case .nextPrimary:
                    statusPill(text: BusScheduleStrings.next, color: primaryAccent)
                case .activeLoop:
                    statusPill(text: BusScheduleStrings.loopActive, color: .green)
                case .upcoming where isFinalRow:
                    statusPill(text: BusScheduleStrings.lastUpper, color: .orange)
                default:
                    Color.clear
                }
            }
            .frame(width: 66, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6.5)
        .background(
            Group {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(rowAccent.opacity(0.12))
                }
            }
        )
        .opacity(row.status == .past ? 0.46 : 1.0)
    }

    private func cellForeground(
        isPast: Bool,
        isPrimaryColumn: Bool,
        isHighlighted: Bool
    ) -> Color {
        if isHighlighted && isPrimaryColumn {
            return .primary
        }
        if isPast {
            return .secondary.opacity(0.65)
        }
        return isPrimaryColumn ? .primary : .secondary
    }

    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

// MARK: - Compact Landscape Right Column

struct CompactLandscapeCompanionColumn: View {
    @Binding var location: Location
    let dayType: DayType
    var isManualOverride: Bool = false
    @ObservedObject var reminderScheduler: LocalBusReminderScheduler
    @Binding var dayTypeBinding: DayType
    var referenceDateOverride: Date? = nil

    var body: some View {
        if let referenceDateOverride {
            content(for: referenceDateOverride)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(for: context.date)
            }
        }
    }

    private func content(for referenceDate: Date) -> some View {
        let currentSeconds = Schedule.secondsFromMidnight(for: referenceDate)
        let primaryState = Schedule.nextDepartureState(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        )
        let upcoming: [String] = {
            guard case .scheduled = primaryState else { return [] }
            return Schedule.upcomingDepartures(
                for: location,
                dayType: dayType,
                currentSecondsFromMidnight: currentSeconds,
                limit: 3
            )
        }()
        let nextTime: String? = {
            if case let .scheduled(time, _) = primaryState { return time }
            return nil
        }()

        return VStack(spacing: 12) {
            OppositeRouteLiveCard(
                location: $location,
                dayType: dayType,
                isManualOverride: isManualOverride,
                isCompact: true,
                referenceDate: referenceDate
            )

            if let nextTime {
                compactUpcomingStrip(nextTime: nextTime, upcoming: upcoming)
            }

            Spacer(minLength: 4)

            VStack(spacing: 8) {
                BusReminderButton(
                    location: location,
                    dayType: dayType,
                    scheduler: reminderScheduler,
                    isCompact: true,
                    referenceDateOverride: referenceDateOverride
                )

                DayTypeToggleView(
                    dayType: $dayTypeBinding,
                    isManualOverride: isManualOverride,
                    isCompact: true
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func compactUpcomingStrip(nextTime: String, upcoming: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(BusScheduleStrings.upcoming)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(2.0)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach(Array(upcoming.enumerated()), id: \.offset) { index, time in
                    VStack(spacing: 1) {
                        Text(time)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(relativeMinutesLabel(nextTime: nextTime, targetTime: time))
                            .font(.system(size: 10.5))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)

                    if index < upcoming.count - 1 {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 1, height: 22)
                    }
                }

                if upcoming.isEmpty {
                    Text("—")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
    }

    private func relativeMinutesLabel(nextTime: String, targetTime: String) -> String {
        guard let nextSeconds = Schedule.secondsFromTimeString(nextTime),
              let targetSeconds = Schedule.secondsFromTimeString(targetTime) else {
            return ""
        }
        return "+\(max(0, (targetSeconds - nextSeconds) / 60))m"
    }
}
