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
    case preAdjustment          // Before outbound flight
    case travelDayOutbound      // Outbound flight day
    case atDestination          // During trip at destination
    case preReturn              // 2 days before return flight
    case travelDayReturn        // Return flight day
    case postReturn             // Recovery at home after return
    
    // Legacy cases for backward compatibility
    case travelDay              // Alias for travelDayOutbound
    case postArrival            // Alias for atDestination
    
    /// Color associated with this stage
    var color: Color {
        switch self {
        case .preAdjustment:
            return .blue
        case .travelDayOutbound, .travelDay:
            return .orange
        case .atDestination, .postArrival:
            return .green
        case .preReturn:
            return .purple
        case .travelDayReturn:
            return .orange
        case .postReturn:
            return .teal
        }
    }
    
    /// Icon for this stage
    var icon: String {
        switch self {
        case .preAdjustment:
            return "clock.arrow.circlepath"
        case .travelDayOutbound, .travelDay:
            return "airplane.departure"
        case .atDestination, .postArrival:
            return "mappin.circle"
        case .preReturn:
            return "arrow.uturn.left.circle"
        case .travelDayReturn:
            return "airplane.arrival"
        case .postReturn:
            return "house.circle"
        }
    }
    
    /// Description for this stage
    var description: String {
        switch self {
        case .preAdjustment:
            return "Pre-flight prep"
        case .travelDayOutbound, .travelDay:
            return "Outbound"
        case .atDestination, .postArrival:
            return "At destination"
        case .preReturn:
            return "Pre-return prep"
        case .travelDayReturn:
            return "Return flight"
        case .postReturn:
            return "Home recovery"
        }
    }
    
    /// Section title for grouping in timeline
    var sectionTitle: String {
        switch self {
        case .preAdjustment:
            return "PREP"
        case .travelDayOutbound, .travelDay:
            return "OUTBOUND"
        case .atDestination, .postArrival:
            return "AT DESTINATION"
        case .preReturn:
            return "PRE-RETURN"
        case .travelDayReturn:
            return "RETURN"
        case .postReturn:
            return "RECOVERY"
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
    
    /// Group schedules by stage for sectioned display
    var schedulesByStage: [(stage: ScheduleStage, schedules: [DailySchedule])] {
        var result: [(ScheduleStage, [DailySchedule])] = []
        var currentStage: ScheduleStage?
        var currentGroup: [DailySchedule] = []
        
        for schedule in dailySchedules {
            if schedule.stage != currentStage {
                if !currentGroup.isEmpty, let stage = currentStage {
                    result.append((stage, currentGroup))
                }
                currentStage = schedule.stage
                currentGroup = [schedule]
            } else {
                currentGroup.append(schedule)
            }
        }
        
        if !currentGroup.isEmpty, let stage = currentStage {
            result.append((stage, currentGroup))
        }
        
        return result
    }
}
