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
    
    /// Current day of month for dynamic calendar icon
    private var currentDayOfMonth: Int {
        Calendar.current.component(.day, from: Date())
    }
    
    /// Dynamic calendar icon showing current day
    private var scheduleIcon: String {
        "\(currentDayOfMonth).square"
    }
    
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
        
        /// Base icon (schedule uses dynamic icon from parent view)
        var icon: String {
            switch self {
            case .family: return "person.3.fill"
            case .trip: return "airplane.departure"
            case .schedule: return "calendar" // Fallback, overridden in view
            }
        }
        
        /// Symbol effect to apply when this tab is selected
        var symbolEffect: any DiscreteSymbolEffect & SymbolEffect {
            switch self {
            case .family:
                return .wiggle.byLayer
            case .trip:
                return .bounce.up.byLayer
            case .schedule:
                return .wiggle.byLayer
            }
        }
    }
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: iconForTab(tab))
                    }
                    .tag(tab)
            }
        }
        .background(
            ExtractTabBarImageViews { imageViews in
                // Only update if we got valid image views
                if !imageViews.isEmpty {
                    tabBarImageViews = imageViews
                }
            }
        )
        .onAppear {
            // Re-extract after a delay to ensure tab bar is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Trigger a re-extraction by toggling a state (the background view will update)
            }
        }
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            animateTabIcon(for: newValue)
        }
        .sensoryFeedback(.selection, trigger: appState.selectedTab)
    }
    
    /// Returns the appropriate icon for a tab (dynamic for schedule)
    private func iconForTab(_ tab: Tab) -> String {
        switch tab {
        case .schedule:
            return scheduleIcon
        default:
            return tab.icon
        }
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
