//
//  DailySchedule.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation
import SwiftUI

/// Represents a single day's sleep schedule for a family member
struct DailySchedule: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let dayLabel: String
    let bedtime: Date
    let wakeTime: Date
    let stage: ScheduleStage
    
    /// Strategy message for travel day (e.g., "Stay up as late as possible")
    let strategyMessage: String?
    
    /// Estimated hotel arrival time (flight arrival + buffer)
    let hotelArrival: Date?
    
    /// Travel direction for context
    let travelDirection: TravelDirection?
    
    /// Body clock offset in minutes (positive = ahead of local, negative = behind local)
    /// Shows how out of sync the body clock is with destination time
    let bodyClockOffsetMinutes: Int
    
    init(
        date: Date,
        dayLabel: String,
        bedtime: Date,
        wakeTime: Date,
        stage: ScheduleStage,
        strategyMessage: String? = nil,
        hotelArrival: Date? = nil,
        travelDirection: TravelDirection? = nil,
        bodyClockOffsetMinutes: Int = 0
    ) {
        self.date = date
        self.dayLabel = dayLabel
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.stage = stage
        self.strategyMessage = strategyMessage
        self.hotelArrival = hotelArrival
        self.travelDirection = travelDirection
        self.bodyClockOffsetMinutes = bodyClockOffsetMinutes
    }
    
    /// Whether this schedule is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Whether this is a travel day with a strategy message
    var hasStrategy: Bool {
        strategyMessage != nil
    }
    
    /// Whether the body clock is in sync (within 30 minutes)
    var isInSync: Bool {
        abs(bodyClockOffsetMinutes) < 30
    }
    
    /// Formatted body clock offset string (e.g., "+3 hrs off", "-1.5 hrs off", "In sync")
    var formattedBodyClockOffset: String {
        if isInSync {
            return "In sync"
        }
        
        let hours = Double(bodyClockOffsetMinutes) / 60.0
        let absHours = abs(hours)
        let sign = hours > 0 ? "+" : ""
        
        if absHours == absHours.rounded() {
            // Whole hours
            let hrs = Int(absHours)
            return "\(sign)\(hrs == 1 ? "1 hr" : "\(hrs) hrs") off"
        } else {
            // Half hours
            return String(format: "%@%.1f hrs off", sign, hours)
        }
    }
    
    /// Formatted bedtime string
    var formattedBedtime: String {
        bedtime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Formatted wake time string
    var formattedWakeTime: String {
        wakeTime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Formatted hotel arrival string
    var formattedHotelArrival: String? {
        hotelArrival?.formatted(date: .omitted, time: .shortened)
    }
    
    /// Formatted date string
    var formattedDate: String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

/// Represents the stage of the jet lag adjustment plan
enum ScheduleStage: Equatable {
    case preAdjustment
    case travelDay
    case postArrival
    
    /// Color associated with this stage
    var color: Color {
        switch self {
        case .preAdjustment:
            return .blue
        case .travelDay:
            return .orange
        case .postArrival:
            return .green
        }
    }
    
    /// Icon for this stage
    var icon: String {
        switch self {
        case .preAdjustment:
            return "clock.arrow.circlepath"
        case .travelDay:
            return "airplane"
        case .postArrival:
            return "checkmark.circle"
        }
    }
    
    /// Description for this stage
    var description: String {
        switch self {
        case .preAdjustment:
            return "Pre-flight adjustment"
        case .travelDay:
            return "Travel day"
        case .postArrival:
            return "Post-arrival"
        }
    }
}

/// Container for a family member's complete schedule
struct FamilyMemberSchedule: Identifiable {
    let id: UUID
    let member: FamilyMember
    let dailySchedules: [DailySchedule]
    
    init(member: FamilyMember, dailySchedules: [DailySchedule]) {
        self.id = member.id
        self.member = member
        self.dailySchedules = dailySchedules
    }
}
