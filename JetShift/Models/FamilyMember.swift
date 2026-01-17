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
    var id: UUID
    var name: String
    var age: Int
    var currentBedtime: Date
    var currentWakeTime: Date
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        currentBedtime: Date,
        currentWakeTime: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.currentBedtime = currentBedtime
        self.currentWakeTime = currentWakeTime
        self.createdAt = createdAt
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
