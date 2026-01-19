//
//  MainTabView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var appState = AppState.shared
    @State private var tabBarImageViews: [Int: UIImageView] = [:]
    
    enum Tab: Int, CaseIterable {
        case family = 0
        case trip = 1
        case schedule = 2
        
        var title: String {
            switch self {
            case .family: return "Family"
            case .trip: return "Trip"
            case .schedule: return "Schedule"
            }
        }
        
        var icon: String {
            switch self {
            case .family: return "person.3.fill"
            case .trip: return "airplane.departure"
            case .schedule: return "calendar"
            }
        }
        
        /// Symbol effect to apply when this tab is selected
        var symbolEffect: any DiscreteSymbolEffect & SymbolEffect {
            switch self {
            case .family:
                return .bounce
            case .trip:
                return .bounce.up.byLayer
            case .schedule:
                return .bounce
            }
        }
    }
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .background(
            ExtractTabBarImageViews { imageViews in
                tabBarImageViews = imageViews
            }
        )
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            animateTabIcon(for: newValue)
        }
        .sensoryFeedback(.selection, trigger: appState.selectedTab)
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
    
    private func animateTabIcon(for tab: Tab) {
        guard let imageView = tabBarImageViews[tab.rawValue] else { return }
        imageView.addSymbolEffect(tab.symbolEffect, options: .nonRepeating)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [FamilyMember.self, Trip.self], inMemory: true)
}
