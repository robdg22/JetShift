//
//  FamilyMember.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation
import SwiftData

@Model
final class FamilyMember {
    var id: UUID = UUID()
    var name: String = ""
    var age: Int = 0
    var currentBedtime: Date = Date()
    var currentWakeTime: Date = Date()
    var createdAt: Date = Date()
    
    /// Whether this person has a fixed wake constraint (work/school)
    var hasWakeConstraint: Bool = true
    
    /// The latest time they must wake by on normal days (work/school)
    var wakeByTime: Date = Date()
    
    /// Whether this member uses a custom strategy (vs trip default)
    var usesCustomStrategy: Bool = false
    
    /// Custom strategy data (if usesCustomStrategy is true)
    var customStrategyData: Data? = nil
    
    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        currentBedtime: Date,
        currentWakeTime: Date,
        hasWakeConstraint: Bool = true,
        wakeByTime: Date? = nil,
        usesCustomStrategy: Bool = false,
        customStrategy: TripStrategy? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.currentBedtime = currentBedtime
        self.currentWakeTime = currentWakeTime
        self.hasWakeConstraint = hasWakeConstraint
        self.wakeByTime = wakeByTime ?? FamilyMember.defaultWakeByTime(for: age)
        self.usesCustomStrategy = usesCustomStrategy
        self.customStrategyData = customStrategy.flatMap { try? JSONEncoder().encode($0) }
        self.createdAt = createdAt
    }
    
    /// The custom strategy for this member (nil = use trip default)
    var customStrategy: TripStrategy? {
        get {
            guard usesCustomStrategy, let data = customStrategyData else { return nil }
            return try? JSONDecoder().decode(TripStrategy.self, from: data)
        }
        set {
            if let strategy = newValue {
                customStrategyData = try? JSONEncoder().encode(strategy)
                usesCustomStrategy = true
            } else {
                customStrategyData = nil
                usesCustomStrategy = false
            }
        }
    }
    
    /// Returns the effective strategy for this member given a trip's default
    func effectiveStrategy(tripDefault: TripStrategy) -> TripStrategy {
        customStrategy ?? tripDefault
    }
    
    /// Default wake-by time based on age (7am for most, earlier for young kids)
    static func defaultWakeByTime(for age: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        
        switch age {
        case 0...5:
            // Young children - no fixed constraint typically
            components.hour = 7
            components.minute = 0
        case 6...12:
            // School age - need to be ready for school
            components.hour = 7
            components.minute = 0
        case 13...17:
            // Teens - school
            components.hour = 7
            components.minute = 0
        default:
            // Adults - work
            components.hour = 7
            components.minute = 0
        }
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// Returns the recommended sleep duration in hours based on age
    var recommendedSleepHours: ClosedRange<Int> {
        switch age {
        case 0...2:
            return 11...14
        case 3...5:
            return 10...13
        case 6...12:
            return 9...12
        case 13...17:
            return 8...10
        default:
            return 7...9
        }
    }
    
    /// Returns the adjustment increment in minutes based on age
    var adjustmentIncrement: Int {
        switch age {
        case 0...5:
            return 20
        case 6...12:
            return 25
        default:
            return 30
        }
    }
    
    /// Returns appropriate SF Symbol for age group
    var ageGroupIcon: String {
        switch age {
        case 0...2:
            return "figure.child"
        case 3...12:
            return "figure.child"
        case 13...17:
            return "figure.stand"
        default:
            return "figure.stand"
        }
    }
    
    /// Formatted bedtime string
    var formattedBedtime: String {
        currentBedtime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Formatted wake time string
    var formattedWakeTime: String {
        currentWakeTime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Formatted wake-by time string
    var formattedWakeByTime: String {
        wakeByTime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Returns suggested bedtime based on age
    static func suggestedBedtime(for age: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        
        switch age {
        case 0...2:
            components.hour = 19
            components.minute = 0
        case 3...5:
            components.hour = 19
            components.minute = 30
        case 6...12:
            components.hour = 20
            components.minute = 0
        case 13...17:
            components.hour = 21
            components.minute = 30
        default:
            components.hour = 22
            components.minute = 30
        }
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// Returns suggested wake time based on age
    static func suggestedWakeTime(for age: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        
        switch age {
        case 0...2:
            components.hour = 6
            components.minute = 30
        case 3...5:
            components.hour = 6
            components.minute = 30
        case 6...12:
            components.hour = 7
            components.minute = 0
        case 13...17:
            components.hour = 7
            components.minute = 30
        default:
            components.hour = 7
            components.minute = 0
        }
        
        return calendar.date(from: components) ?? Date()
    }
}
