//
//  ContentView.swift
//  Bus_Schedule
//
//  Created by 卢浩然 on 2024/11/11.
//

import SwiftUI

struct ContentView: View {
    @State private var location: Location = .phIINewCampus
    @State private var dayType: DayType = .weekday
    
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
            DayTypeToggleView(dayType: $dayType)
            
            Spacer()
        }
        .onAppear {
            // 设置初始日期类型
            let today = Calendar.current.component(.weekday, from: Date())
            dayType = today == 1 || today == 7 ? .weekend : .weekday
        }
    }
}

// 预览
#Preview {
    ContentView()
}
