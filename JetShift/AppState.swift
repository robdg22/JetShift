//
//  AppState.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI

/// Observable app state for cross-view communication
@Observable
final class AppState {
    /// The currently selected tab
    var selectedTab: MainTabView.Tab = .family
    
    /// Shared instance
    static let shared = AppState()
    
    private init() {}
    
    /// Navigate to the schedule tab
    func showSchedule() {
        withAnimation(.smooth) {
            selectedTab = .schedule
        }
    }
    
    /// Navigate to the trip tab
    func showTrip() {
        withAnimation(.smooth) {
            selectedTab = .trip
        }
    }
}
