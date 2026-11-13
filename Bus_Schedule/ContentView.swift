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
    @State private var location: Location
    @State private var dayType: DayType
    @State private var isManualOverride: Bool
    @StateObject private var reminderScheduler: LocalBusReminderScheduler
    private let referenceDateOverride: Date?
    private let usesLiveStore: Bool

    init() {
        _location = State(initialValue: SharedStore.readPrimaryRoute())
        let effective = DayType.effective()
        _dayType = State(initialValue: effective.dayType)
        _isManualOverride = State(initialValue: effective.isManualOverride)
        _reminderScheduler = StateObject(wrappedValue: LocalBusReminderScheduler())
        referenceDateOverride = nil
        usesLiveStore = true
    }

    #if DEBUG
    init(
        previewLocation: Location,
        previewDayType: DayType,
        previewIsManualOverride: Bool = false,
        previewDate: Date,
        previewDefaults: UserDefaults = .standard
    ) {
        _location = State(initialValue: previewLocation)
        _dayType = State(initialValue: previewDayType)
        _isManualOverride = State(initialValue: previewIsManualOverride)
        _reminderScheduler = StateObject(wrappedValue: LocalBusReminderScheduler(defaults: previewDefaults))
        referenceDateOverride = previewDate
        usesLiveStore = false
    }
    #endif

    private var locationBinding: Binding<Location> {
        Binding(
            get: { location },
            set: { newValue in
                location = newValue
                if usesLiveStore {
                    SharedStore.writePrimaryRoute(newValue)
                }
            }
        )
    }

    private var dayTypeBinding: Binding<DayType> {
        Binding(
            get: { dayType },
            set: { newValue in
                let reference = referenceDateOverride ?? Date()
                let auto = DayType.automatic(for: reference)
                dayType = newValue
                isManualOverride = (newValue != auto)
                if usesLiveStore {
                    // SharedStore writes to App Group UserDefaults and republishes
                    // the latest state to the paired Watch.
                    SharedStore.writeOverride(newValue == auto ? nil : newValue)
                }
            }
        )
    }

    private var routeLabel: String {
        WidgetTheme.routeLabel(for: location)
    }

    var body: some View {
        GeometryReader { viewport in
            switch AdaptiveViewportMode.resolve(size: viewport.size) {
            case let .singleColumn(isCompact):
                singleColumnBody(viewport: viewport.size, isCompact: isCompact)

            case .bookSpread:
                bookSpreadBody(viewport: viewport.size)

            case .tallExpanded:
                tallExpandedBody(viewport: viewport.size)

            case .compactLandscape:
                compactLandscapeBody(viewport: viewport.size)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            guard usesLiveStore else { return }
            SharedStore.startWatchSync()
            applyRoutePreference()
            applyEffectiveDayType()
            Task { await reminderScheduler.refresh() }
        }
        .onChange(of: scenePhase) { _, newValue in
            guard usesLiveStore, newValue == .active else { return }
            SharedStore.startWatchSync()
            applyRoutePreference()
            applyEffectiveDayType()
            Task { await reminderScheduler.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification).receive(on: RunLoop.main)) { _ in
            guard usesLiveStore else { return }
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            guard usesLiveStore else { return }
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .primaryRouteDidChange).receive(on: RunLoop.main)) { _ in
            guard usesLiveStore else { return }
            applyRoutePreference()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dayTypeOverrideDidChange).receive(on: RunLoop.main)) { _ in
            guard usesLiveStore else { return }
            // Fired when a synced override arrives from the counterpart device.
            // Re-read the effective day type from SharedStore.
            applyEffectiveDayType()
        }
    }

    // MARK: - Single Column (Phone / iPhone Duo Outer Cover / Narrow Split View)

    private func singleColumnBody(viewport: CGSize, isCompact: Bool) -> some View {
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
                    isCompact: isCompact,
                    referenceDateOverride: referenceDateOverride
                )
                .padding(.top, isCompact ? 18 : 32)
                .padding(.horizontal, isCompact ? 20 : 24)

                Spacer(minLength: isCompact ? 12 : 20)

                BusReminderButton(
                    location: location,
                    dayType: dayType,
                    scheduler: reminderScheduler,
                    isCompact: isCompact,
                    referenceDateOverride: referenceDateOverride
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
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity, minHeight: viewport.height, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Book Spread (iPhone Duo Unfolded Inner Display & Wide Regular Windows)

    private func bookSpreadBody(viewport: CGSize) -> some View {
        let isTightHeight = viewport.height < 640
        let verticalPadding: CGFloat = isTightHeight ? 16 : 24
        let innerHeight = max(0, viewport.height - verticalPadding * 2)

        return HStack(alignment: .top, spacing: 0) {
            // Left Page: Primary Campus Departure Board
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header(isCompact: false)
                        .padding(.horizontal, 4)

                    LocationToggleView(location: locationBinding, isCompact: isTightHeight)
                        .padding(.top, isTightHeight ? 14 : 20)

                    Spacer(minLength: isTightHeight ? 16 : 28)

                    NextBusView(
                        location: location,
                        dayType: dayType,
                        isManualOverride: isManualOverride,
                        isCompact: false,
                        heroFontSize: isTightHeight ? 80 : 88,
                        sectionSpacing: isTightHeight ? 20 : 28,
                        referenceDateOverride: referenceDateOverride
                    )
                    .padding(.horizontal, 4)

                    Spacer(minLength: isTightHeight ? 16 : 28)

                    BusReminderButton(
                        location: location,
                        dayType: dayType,
                        scheduler: reminderScheduler,
                        isCompact: isTightHeight,
                        referenceDateOverride: referenceDateOverride
                    )
                    .padding(.bottom, isTightHeight ? 8 : 12)

                    DayTypeToggleView(
                        dayType: dayTypeBinding,
                        isManualOverride: isManualOverride,
                        isCompact: isTightHeight
                    )
                }
                .frame(maxWidth: 440, minHeight: innerHeight, alignment: .top)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Center Fold Crease Safe Gutter (Exact 50% Midline)
            HingeSpineDivider()

            // Right Page: Live Return Status + Paired Timetable Booklet
            DuoCompanionBoard(
                location: locationBinding,
                dayType: dayType,
                isManualOverride: isManualOverride,
                expandsVertically: true,
                referenceDateOverride: referenceDateOverride
            )
            .frame(maxWidth: 450, maxHeight: .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: 1080, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tall Expanded (iPhone Duo Rotated Vertical / Tabletop Stand & 2/3 Split)

    private func tallExpandedBody(viewport: CGSize) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    header(isCompact: false)
                        .padding(.horizontal, 4)

                    LocationToggleView(location: locationBinding, isCompact: false)
                        .padding(.top, 14)

                    NextBusView(
                        location: location,
                        dayType: dayType,
                        isManualOverride: isManualOverride,
                        isCompact: false,
                        heroFontSize: 76,
                        sectionSpacing: 18,
                        referenceDateOverride: referenceDateOverride
                    )
                    .padding(.top, 18)
                    .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        BusReminderButton(
                            location: location,
                            dayType: dayType,
                            scheduler: reminderScheduler,
                            isCompact: true,
                            referenceDateOverride: referenceDateOverride
                        )

                        DayTypeToggleView(
                            dayType: dayTypeBinding,
                            isManualOverride: isManualOverride,
                            isCompact: true
                        )
                    }
                    .padding(.top, 16)
                }

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 0.5)
                    .padding(.vertical, 16)

                DuoCompanionBoard(
                    location: locationBinding,
                    dayType: dayType,
                    isManualOverride: isManualOverride,
                    expandsVertically: false,
                    referenceDateOverride: referenceDateOverride
                )
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity, minHeight: viewport.height, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Compact Landscape (Phone / Outer Cover Landscape)

    private func compactLandscapeBody(viewport: CGSize) -> some View {
        let verticalPadding: CGFloat = 12
        let innerHeight = max(0, viewport.height - verticalPadding * 2)

        return ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 0) {
                    header(isCompact: true)
                        .padding(.horizontal, 4)

                    LocationToggleView(location: locationBinding, isCompact: true)
                        .padding(.top, 10)

                    Spacer(minLength: 10)

                    NextBusView(
                        location: location,
                        dayType: dayType,
                        isManualOverride: isManualOverride,
                        isCompact: true,
                        heroFontSize: 60,
                        sectionSpacing: 14,
                        showsUpcoming: false,
                        referenceDateOverride: referenceDateOverride
                    )
                    .padding(.horizontal, 4)

                    Spacer(minLength: 4)
                }
                .frame(maxWidth: .infinity, minHeight: innerHeight, alignment: .top)

                CompactLandscapeCompanionColumn(
                    location: locationBinding,
                    dayType: dayType,
                    isManualOverride: isManualOverride,
                    reminderScheduler: reminderScheduler,
                    dayTypeBinding: dayTypeBinding,
                    referenceDateOverride: referenceDateOverride
                )
                .frame(maxWidth: .infinity, minHeight: innerHeight, alignment: .top)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: 860)
            .frame(maxWidth: .infinity, minHeight: viewport.height, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Header

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

#if DEBUG
private func duoPreviewDate(hour: Int, minute: Int, second: Int = 18) -> Date {
    Calendar.current.date(
        from: DateComponents(year: 2026, month: 5, day: 6, hour: hour, minute: minute, second: second)
    ) ?? .now
}

#Preview("Standard iPhone") {
    ContentView(
        previewLocation: .phIINewCampus,
        previewDayType: .weekday,
        previewDate: duoPreviewDate(hour: 17, minute: 35)
    )
}

#Preview("iPhone Duo · Outer Cover", traits: .fixedLayout(width: 466, height: 678)) {
    ContentView(
        previewLocation: .phIINewCampus,
        previewDayType: .weekday,
        previewDate: duoPreviewDate(hour: 8, minute: 12)
    )
}

#Preview("iPhone Duo · Book Open", traits: .fixedLayout(width: 951, height: 669)) {
    ContentView(
        previewLocation: .phIINewCampus,
        previewDayType: .weekday,
        previewDate: duoPreviewDate(hour: 8, minute: 12)
    )
}

#Preview("iPhone Duo · Tall Unfolded", traits: .fixedLayout(width: 669, height: 951)) {
    ContentView(
        previewLocation: .phIINewCampus,
        previewDayType: .weekday,
        previewDate: duoPreviewDate(hour: 17, minute: 35)
    )
}
#endif
