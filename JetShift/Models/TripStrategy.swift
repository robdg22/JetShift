//
//  TripStrategy.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation
import SwiftUI

/// Represents the jet lag adjustment strategy for a trip
enum TripStrategy: Codable, Hashable, Sendable {
    case fullAdjustment
    case partialAdjustment(percentage: Double)
    case minimizeTotal
    case noAdjustment
    
    /// Display name for the strategy
    var displayName: String {
        switch self {
        case .fullAdjustment:
            return "Full Adjustment"
        case .partialAdjustment(let percentage):
            return "Partial (\(Int(percentage * 100))%)"
        case .minimizeTotal:
            return "Minimize Total"
        case .noAdjustment:
            return "No Adjustment"
        }
    }
    
    /// Short display name for compact UI (e.g., badges)
    var shortDisplayName: String {
        switch self {
        case .fullAdjustment:
            return "Full"
        case .partialAdjustment(let percentage):
            return "\(Int(percentage * 100))%"
        case .minimizeTotal:
            return "Min"
        case .noAdjustment:
            return "None"
        }
    }
    
    /// Short description of the strategy
    var shortDescription: String {
        switch self {
        case .fullAdjustment:
            return "Fully adjust to destination time"
        case .partialAdjustment:
            return "Partially adjust, wake early at destination"
        case .minimizeTotal:
            return "Balance outbound and return adjustment"
        case .noAdjustment:
            return "Stay on home time"
        }
    }
    
    /// Detailed description for the strategy explanation
    var detailedDescription: String {
        switch self {
        case .fullAdjustment:
            return "Shift your schedule completely to match destination time. Best for trips 10+ days where you want to experience local schedules fully."
        case .partialAdjustment(let percentage):
            return "Shift \(Int(percentage * 100))% toward destination time. You'll wake earlier than locals but enjoy attractions before crowds. Much faster recovery when you return home."
        case .minimizeTotal:
            return "Balance adjustment between outbound and return. Start shifting back before you leave to minimize total recovery time across the whole trip."
        case .noAdjustment:
            return "Keep your home timezone schedule throughout. Best for very short trips (1-3 days) where adjustment isn't worth it."
        }
    }
    
    /// Icon for the strategy
    var icon: String {
        switch self {
        case .fullAdjustment:
            return "clock.badge.checkmark"
        case .partialAdjustment:
            return "sunrise.fill"
        case .minimizeTotal:
            return "arrow.left.arrow.right"
        case .noAdjustment:
            return "house.fill"
        }
    }
    
    /// Color for the strategy
    var color: Color {
        switch self {
        case .fullAdjustment:
            return .blue
        case .partialAdjustment:
            return .orange
        case .minimizeTotal:
            return .purple
        case .noAdjustment:
            return .gray
        }
    }
    
    /// Pros for this strategy
    var pros: [String] {
        switch self {
        case .fullAdjustment:
            return [
                "Experience destination on local time",
                "Normal dinner and evening activities",
                "Best for long trips (10+ days)"
            ]
        case .partialAdjustment:
            return [
                "Beat the crowds with early mornings",
                "Kids adjust more easily",
                "Much faster recovery at home",
                "Less total jet lag overall"
            ]
        case .minimizeTotal:
            return [
                "Optimizes total recovery time",
                "Balanced approach for medium trips",
                "Arrive home already partially adjusted"
            ]
        case .noAdjustment:
            return [
                "Zero jet lag",
                "Perfect for very short trips",
                "No schedule changes needed"
            ]
        }
    }
    
    /// Cons for this strategy
    var cons: [String] {
        switch self {
        case .fullAdjustment:
            return [
                "Longest total recovery time",
                "Jet lag on both outbound and return",
                "Takes 5-7 days to fully adjust each way"
            ]
        case .partialAdjustment:
            return [
                "May miss late evening activities",
                "Earlier bedtimes than locals",
                "Tired by 8-9pm local time"
            ]
        case .minimizeTotal:
            return [
                "More complex schedule",
                "Need to track pre-return shifts",
                "Not fully on local time"
            ]
        case .noAdjustment:
            return [
                "May feel out of sync with locals",
                "Only works for 1-3 day trips",
                "Miss morning activities if waking late"
            ]
        }
    }
    
    /// The percentage of adjustment (1.0 for full, 0.0 for none)
    var adjustmentPercentage: Double {
        switch self {
        case .fullAdjustment:
            return 1.0
        case .partialAdjustment(let percentage):
            return percentage
        case .minimizeTotal:
            return 0.7
        case .noAdjustment:
            return 0.0
        }
    }
    
    /// Common partial adjustment options
    static let partialOptions: [TripStrategy] = [
        .partialAdjustment(percentage: 0.5),
        .partialAdjustment(percentage: 0.6),
        .partialAdjustment(percentage: 0.7)
    ]
    
    /// All main strategy types for picker
    static let allMainTypes: [TripStrategy] = [
        .fullAdjustment,
        .partialAdjustment(percentage: 0.6),
        .minimizeTotal,
        .noAdjustment
    ]
}
