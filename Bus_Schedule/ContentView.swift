//
//  ContentView.swift
//  Bus_Schedule
//
//  Created by 卢浩然 on 2024/11/11.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var location: Location = .phIINewCampus
    @State private var dayType: DayType = .weekday
    @State private var followsAutomaticDayType = true

    private var dayTypeBinding: Binding<DayType> {
        Binding(
            get: { dayType },
            set: { newValue in
                dayType = newValue
                followsAutomaticDayType = newValue == Self.automaticDayType(for: Date())
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
            syncDayTypeWithCurrentDate()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            syncDayTypeWithCurrentDate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            syncDayTypeWithCurrentDate()
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

    private func syncDayTypeWithCurrentDate(referenceDate: Date = Date()) {
        guard followsAutomaticDayType else { return }
        dayType = Self.automaticDayType(for: referenceDate)
    }

    private static func automaticDayType(for date: Date) -> DayType {
        let weekday = Calendar.current.component(.weekday, from: date)

        switch weekday {
        case 7:
            return .saturday
        case 1:
            return .sundayOrHoliday
        default:
            return .weekday
        }
    }
}

#Preview {
    ContentView()
}
