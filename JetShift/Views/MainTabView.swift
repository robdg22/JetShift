//
//  MainTabView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .family
    
    enum Tab: String, CaseIterable {
        case family = "Family"
        case trip = "Trip"
        case schedule = "Schedule"
        
        var icon: String {
            switch self {
            case .family: return "person.3.fill"
            case .trip: return "airplane.departure"
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
        case .trip:
            TripView()
        case .schedule:
            ScheduleView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [FamilyMember.self, Trip.self], inMemory: true)
}
