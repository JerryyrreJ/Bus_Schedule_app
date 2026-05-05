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
    
    var body: some View {
        VStack(spacing: 50) {
            // 标题部分
            VStack(spacing: 12) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 35))
                    .foregroundColor(location == .phIINewCampus ? .green : .blue)
                
                Text("Campus Shuttle \nSchedule")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Real-time bus departure information\nbetween campuses")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 55)
            
            // 位置切换
            LocationToggleView(location: $location)
                .padding(.horizontal)
            
            // 下一班车信息
            NextBusView(location: location, dayType: dayType)
                .padding(.horizontal)
            
            // 日期类型切换
            DayTypeToggleView(dayType: dayTypeBinding)
            
            Spacer()
        }
        .onAppear {
            syncDayTypeWithCurrentDate()
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            guard newValue == .active else { return }
            syncDayTypeWithCurrentDate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            syncDayTypeWithCurrentDate()
        }
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

// 预览
#Preview {
    ContentView()
}
