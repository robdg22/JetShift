//
//  MainTabView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .family
    
    enum Tab: String, CaseIterable {
        case family = "Family"
        case flight = "Flight"
        case schedule = "Schedule"
        
        var icon: String {
            switch self {
            case .family: return "person.3.fill"
            case .flight: return "airplane.departure"
            case .schedule: return "calendar"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
    
    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .family:
            FamilyView()
        case .flight:
            FlightView()
        case .schedule:
            ScheduleView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [FamilyMember.self, Flight.self], inMemory: true)
}
