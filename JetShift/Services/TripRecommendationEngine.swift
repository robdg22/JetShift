//
//  TripRecommendationEngine.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation

/// Engine for recommending jet lag strategies based on trip parameters
struct TripRecommendationEngine {
    
    /// Recommends a strategy based on trip parameters
    /// - Parameters:
    ///   - daysAtDestination: Number of days at destination
    ///   - timezoneOffset: Timezone difference in hours (positive = east, negative = west)
    ///   - familyMembers: Array of family members for age-based adjustments
    /// - Returns: Recommended TripStrategy
    static func recommendStrategy(
        daysAtDestination: Int,
        timezoneOffset: Int,
        familyMembers: [FamilyMember]
    ) -> TripStrategy {
        let absOffset = abs(timezoneOffset)
        
        // Very short trips - no adjustment
        if daysAtDestination <= 3 {
            return .noAdjustment
        }
        
        // Short-medium trips (4-6 days)
        if daysAtDestination <= 6 {
            if absOffset <= 5 {
                return .partialAdjustment(percentage: 0.5)
            } else {
                return .partialAdjustment(percentage: 0.6)
            }
        }
        
        // Medium trips (7-10 days)
        if daysAtDestination <= 10 {
            // Check for young children who benefit from partial
            let hasYoungChildren = familyMembers.contains { $0.age <= 8 }
            
            if absOffset <= 5 {
                // Smaller timezone difference - can do full or minimize total
                if hasYoungChildren {
                    return .partialAdjustment(percentage: 0.7)
                } else {
                    return .minimizeTotal
                }
            } else {
                // Large timezone shift - partial is safer
                return .partialAdjustment(percentage: 0.7)
            }
        }
        
        // Long trips (10+ days) - full adjustment
        return .fullAdjustment
    }
    
    /// Generates explanation for why a strategy is recommended
    /// - Parameters:
    ///   - strategy: The recommended strategy
    ///   - daysAtDestination: Number of days at destination
    ///   - timezoneOffset: Timezone difference in hours
    ///   - familyMembers: Array of family members
    /// - Returns: Human-readable explanation string
    static func explanation(
        for strategy: TripStrategy,
        daysAtDestination: Int,
        timezoneOffset: Int,
        familyMembers: [FamilyMember]
    ) -> String {
        let direction = timezoneOffset > 0 ? "east" : "west"
        let absOffset = abs(timezoneOffset)
        let hasYoungChildren = familyMembers.contains { $0.age <= 8 }
        let hasTeens = familyMembers.contains { $0.age >= 13 && $0.age < 18 }
        
        switch strategy {
        case .noAdjustment:
            return "For a \(daysAtDestination)-day trip, adjusting your schedule isn't worth the disruption. Stay on home time and enjoy the trip!"
            
        case .partialAdjustment(let percentage):
            var reasons: [String] = []
            
            if daysAtDestination <= 6 {
                reasons.append("your \(daysAtDestination)-day trip is short")
            }
            
            if absOffset >= 5 {
                reasons.append("the \(absOffset)-hour \(direction)ward shift is significant")
            }
            
            if hasYoungChildren {
                reasons.append("young children naturally wake early anyway")
            }
            
            let reasonText = reasons.isEmpty ? "" : " because " + reasons.joined(separator: " and ")
            
            return "We recommend \(Int(percentage * 100))% adjustment\(reasonText). You'll wake earlier than locals (around 5-6am) but beat the crowds at attractions. Recovery at home will be faster."
            
        case .minimizeTotal:
            return "For a \(daysAtDestination)-day trip with a \(absOffset)-hour shift, balancing adjustment between outbound and return minimizes total disruption. You'll start shifting back 2 days before coming home."
            
        case .fullAdjustment:
            var text = "With \(daysAtDestination) days at your destination, you have time to fully adjust."
            
            if hasTeens {
                text += " Teens can handle the full shift well and will want to enjoy evening activities."
            }
            
            if timezoneOffset > 0 {
                text += " Note: Eastward travel takes longer to adjust (about 1 day per timezone)."
            }
            
            return text
        }
    }
    
    /// Estimates recovery days for a strategy
    /// - Parameters:
    ///   - strategy: The chosen strategy
    ///   - timezoneOffset: Timezone difference in hours
    /// - Returns: Estimated recovery days after return
    static func estimatedRecoveryDays(
        for strategy: TripStrategy,
        timezoneOffset: Int
    ) -> Int {
        let absOffset = abs(timezoneOffset)
        
        switch strategy {
        case .noAdjustment:
            return 0
            
        case .partialAdjustment(let percentage):
            // Partial adjustment means faster recovery
            let adjustedOffset = Double(absOffset) * (1.0 - percentage)
            return max(1, Int(ceil(adjustedOffset)))
            
        case .minimizeTotal:
            // Pre-return adjustment reduces recovery
            return max(1, absOffset / 3)
            
        case .fullAdjustment:
            // Full recovery time based on direction
            // Eastward is harder (1 day per hour), westward is easier (0.5-0.7 days per hour)
            if timezoneOffset > 0 {
                return absOffset
            } else {
                return max(1, Int(ceil(Double(absOffset) * 0.7)))
            }
        }
    }
    
    /// Compares all strategies for a trip
    /// - Parameters:
    ///   - daysAtDestination: Number of days at destination
    ///   - timezoneOffset: Timezone difference in hours
    ///   - familyMembers: Array of family members
    /// - Returns: Array of strategy comparisons
    static func compareStrategies(
        daysAtDestination: Int,
        timezoneOffset: Int,
        familyMembers: [FamilyMember]
    ) -> [StrategyComparison] {
        let recommended = recommendStrategy(
            daysAtDestination: daysAtDestination,
            timezoneOffset: timezoneOffset,
            familyMembers: familyMembers
        )
        
        return TripStrategy.allMainTypes.map { strategy in
            StrategyComparison(
                strategy: strategy,
                recoveryDays: estimatedRecoveryDays(for: strategy, timezoneOffset: timezoneOffset),
                explanation: explanation(
                    for: strategy,
                    daysAtDestination: daysAtDestination,
                    timezoneOffset: timezoneOffset,
                    familyMembers: familyMembers
                ),
                isRecommended: strategiesMatch(strategy, recommended)
            )
        }
    }
    
    private static func strategiesMatch(_ a: TripStrategy, _ b: TripStrategy) -> Bool {
        switch (a, b) {
        case (.fullAdjustment, .fullAdjustment):
            return true
        case (.partialAdjustment, .partialAdjustment):
            return true
        case (.minimizeTotal, .minimizeTotal):
            return true
        case (.noAdjustment, .noAdjustment):
            return true
        default:
            return false
        }
    }
}

/// Represents a strategy comparison result
struct StrategyComparison: Identifiable {
    let id = UUID()
    let strategy: TripStrategy
    let recoveryDays: Int
    let explanation: String
    let isRecommended: Bool
}
