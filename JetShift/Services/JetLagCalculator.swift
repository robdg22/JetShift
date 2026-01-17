//
//  JetLagCalculator.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation

/// Service for calculating jet lag adjustment schedules
struct JetLagCalculator {
    
    /// Number of pre-flight adjustment days
    static let preFlightDays = 3
    
    /// Number of post-arrival days for gradual adjustment
    static let postArrivalDays = 4
    
    /// Buffer time (in hours) from flight arrival to hotel check-in
    static let hotelArrivalBufferHours = 2
    
    /// Late bedtime hour for "stay up late" strategy (westward)
    static let stayUpLateBedtimeHour = 23 // 11 PM
    
    /// Target bedtime hour for eastward travel day
    static let eastwardTargetBedtimeHour = 22 // 10 PM - stay awake as long as possible
    
    /// Calculate the complete adjustment schedule for a family member
    /// - Parameters:
    ///   - member: The family member to calculate for
    ///   - flight: The flight details
    /// - Returns: Array of daily schedules covering pre-flight, travel day, and post-arrival
    static func calculateSchedule(for member: FamilyMember, flight: Flight) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let calendar = Calendar.current
        
        // Pre-flight adjustment days (3 days before)
        schedules.append(contentsOf: calculatePreFlightSchedules(
            for: member,
            flight: flight,
            calendar: calendar
        ))
        
        // Travel day (Day 0)
        schedules.append(calculateTravelDaySchedule(
            for: member,
            flight: flight,
            calendar: calendar
        ))
        
        // Post-arrival days (4 days of gradual adjustment)
        schedules.append(contentsOf: calculatePostArrivalSchedules(
            for: member,
            flight: flight,
            calendar: calendar
        ))
        
        return schedules
    }
    
    // MARK: - Pre-Flight Calculation
    
    private static func calculatePreFlightSchedules(
        for member: FamilyMember,
        flight: Flight,
        calendar: Calendar
    ) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let direction = flight.travelDirection
        let increment = member.adjustmentIncrement
        let travelDate = flight.departureDate
        let totalTimezoneOffsetMinutes = abs(flight.timezoneOffset) * 60
        
        for dayOffset in (-preFlightDays)...(-1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: travelDate) else {
                continue
            }
            
            let adjustmentDays = preFlightDays + dayOffset + 1 // 1, 2, 3 days of adjustment
            let totalAdjustedMinutes = adjustmentDays * increment
            
            let adjustedBedtime: Date
            let adjustedWakeTime: Date
            
            switch direction {
            case .east:
                // Eastward travel: shift earlier (subtract time)
                adjustedBedtime = adjustTime(member.currentBedtime, byMinutes: -totalAdjustedMinutes)
                adjustedWakeTime = adjustTime(member.currentWakeTime, byMinutes: -totalAdjustedMinutes)
            case .west:
                // Westward travel: shift later (add time)
                adjustedBedtime = adjustTime(member.currentBedtime, byMinutes: totalAdjustedMinutes)
                adjustedWakeTime = adjustTime(member.currentWakeTime, byMinutes: totalAdjustedMinutes)
            case .none:
                // No timezone change: keep original times
                adjustedBedtime = member.currentBedtime
                adjustedWakeTime = member.currentWakeTime
            }
            
            // Calculate body clock offset:
            // Pre-flight: how much we've adjusted vs total needed
            // Remaining offset = total - adjusted so far
            let remainingOffset = totalTimezoneOffsetMinutes - totalAdjustedMinutes
            let bodyClockOffset: Int
            switch direction {
            case .east:
                // Eastward: body clock is behind destination (negative offset remaining)
                bodyClockOffset = -remainingOffset
            case .west:
                // Westward: body clock is ahead of destination (positive offset remaining)
                bodyClockOffset = remainingOffset
            case .none:
                bodyClockOffset = 0
            }
            
            let dayLabel = dayLabelForPreFlight(daysRemaining: abs(dayOffset))
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: dayLabel,
                bedtime: adjustedBedtime,
                wakeTime: adjustedWakeTime,
                stage: .preAdjustment,
                travelDirection: direction,
                bodyClockOffsetMinutes: bodyClockOffset
            ))
        }
        
        return schedules
    }
    
    // MARK: - Travel Day Calculation
    
    private static func calculateTravelDaySchedule(
        for member: FamilyMember,
        flight: Flight,
        calendar: Calendar
    ) -> DailySchedule {
        let direction = flight.travelDirection
        let travelDate = flight.departureDate
        let totalTimezoneOffsetMinutes = flight.timezoneOffset * 60 // Keep sign for direction
        
        // Calculate hotel arrival (flight arrival + 2 hour buffer)
        let hotelArrival = calendar.date(
            byAdding: .hour,
            value: hotelArrivalBufferHours,
            to: flight.arrivalTime
        ) ?? flight.arrivalTime
        
        // Pre-flight adjustment amount
        let preFlightAdjustment = preFlightDays * member.adjustmentIncrement
        
        // Get strategy message and target bedtime based on direction
        let strategyMessage: String
        let targetBedtime: Date
        let targetWakeTime: Date
        
        switch direction {
        case .west:
            // Westward: Stay up as late as possible
            strategyMessage = "Stay up as late as possible"
            targetBedtime = createTime(hour: stayUpLateBedtimeHour, minute: 0, from: travelDate, calendar: calendar)
            targetWakeTime = createTime(hour: 8, minute: 0, from: travelDate, calendar: calendar)
            
        case .east:
            // Eastward: Short nap if tired, then stay awake
            strategyMessage = "Short morning nap if tired, then stay awake as long as possible"
            targetBedtime = createTime(hour: eastwardTargetBedtimeHour, minute: 0, from: travelDate, calendar: calendar)
            targetWakeTime = createTime(hour: 7, minute: 0, from: travelDate, calendar: calendar)
            
        case .none:
            // No timezone change
            strategyMessage = "Maintain regular schedule"
            targetBedtime = member.currentBedtime
            targetWakeTime = member.currentWakeTime
        }
        
        // Body clock offset on travel day:
        // Full timezone offset minus what was adjusted pre-flight
        let remainingOffset = abs(totalTimezoneOffsetMinutes) - preFlightAdjustment
        let bodyClockOffset: Int
        switch direction {
        case .east:
            bodyClockOffset = -remainingOffset
        case .west:
            bodyClockOffset = remainingOffset
        case .none:
            bodyClockOffset = 0
        }
        
        return DailySchedule(
            date: travelDate,
            dayLabel: "Travel Day",
            bedtime: targetBedtime,
            wakeTime: targetWakeTime,
            stage: .travelDay,
            strategyMessage: strategyMessage,
            hotelArrival: hotelArrival,
            travelDirection: direction,
            bodyClockOffsetMinutes: bodyClockOffset
        )
    }
    
    // MARK: - Post-Arrival Calculation
    
    private static func calculatePostArrivalSchedules(
        for member: FamilyMember,
        flight: Flight,
        calendar: Calendar
    ) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let direction = flight.travelDirection
        let increment = member.adjustmentIncrement
        let travelDate = flight.departureDate
        let totalTimezoneOffsetMinutes = abs(flight.timezoneOffset) * 60
        
        // Pre-flight adjustment already done
        let preFlightAdjustment = preFlightDays * increment
        
        // Starting point for post-arrival (from travel day strategy)
        let startingBedtime: Date
        let startingWakeTime: Date
        
        switch direction {
        case .west:
            // Started late (11pm), need to shift EARLIER toward target
            startingBedtime = createTime(hour: stayUpLateBedtimeHour, minute: 0, from: travelDate, calendar: calendar)
            startingWakeTime = createTime(hour: 8, minute: 0, from: travelDate, calendar: calendar)
            
        case .east:
            // Started at 10pm, need to shift LATER toward target (or earlier to normal)
            startingBedtime = createTime(hour: eastwardTargetBedtimeHour, minute: 0, from: travelDate, calendar: calendar)
            startingWakeTime = createTime(hour: 7, minute: 0, from: travelDate, calendar: calendar)
            
        case .none:
            startingBedtime = member.currentBedtime
            startingWakeTime = member.currentWakeTime
        }
        
        for dayOffset in 1...postArrivalDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: travelDate) else {
                continue
            }
            
            let adjustedBedtime: Date
            let adjustedWakeTime: Date
            
            // Calculate gradual shift toward target
            let postArrivalAdjustmentMinutes = dayOffset * increment
            
            switch direction {
            case .west:
                // Westward: shift bedtime EARLIER each day (toward normal)
                adjustedBedtime = adjustTime(startingBedtime, byMinutes: -postArrivalAdjustmentMinutes)
                adjustedWakeTime = adjustTime(startingWakeTime, byMinutes: -postArrivalAdjustmentMinutes)
                
            case .east:
                // Eastward: shift bedtime LATER each day (toward normal)
                adjustedBedtime = adjustTime(startingBedtime, byMinutes: postArrivalAdjustmentMinutes)
                adjustedWakeTime = adjustTime(startingWakeTime, byMinutes: postArrivalAdjustmentMinutes)
                
            case .none:
                adjustedBedtime = member.currentBedtime
                adjustedWakeTime = member.currentWakeTime
            }
            
            // Body clock offset post-arrival:
            // Remaining offset after pre-flight minus post-arrival adjustment
            let totalAdjusted = preFlightAdjustment + postArrivalAdjustmentMinutes
            let remainingOffset = max(0, totalTimezoneOffsetMinutes - totalAdjusted)
            let bodyClockOffset: Int
            switch direction {
            case .east:
                bodyClockOffset = -remainingOffset
            case .west:
                bodyClockOffset = remainingOffset
            case .none:
                bodyClockOffset = 0
            }
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: "Day \(dayOffset)",
                bedtime: adjustedBedtime,
                wakeTime: adjustedWakeTime,
                stage: .postArrival,
                travelDirection: direction,
                bodyClockOffsetMinutes: bodyClockOffset
            ))
        }
        
        return schedules
    }
    
    // MARK: - Helper Methods
    
    /// Adjust a time by a specified number of minutes
    private static func adjustTime(_ time: Date, byMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .minute, value: minutes, to: time) ?? time
    }
    
    /// Create a time on a specific date
    private static func createTime(hour: Int, minute: Int, from date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? date
    }
    
    /// Convert a time from one timezone to another
    private static func convertToDestinationTime(
        _ time: Date,
        from sourceTimezone: String,
        to destinationTimezone: String
    ) -> Date {
        guard let sourceTZ = TimeZone(identifier: sourceTimezone),
              let destTZ = TimeZone(identifier: destinationTimezone) else {
            return time
        }
        
        let sourceOffset = sourceTZ.secondsFromGMT(for: time)
        let destOffset = destTZ.secondsFromGMT(for: time)
        let difference = destOffset - sourceOffset
        
        return time.addingTimeInterval(TimeInterval(difference))
    }
    
    /// Generate day label for pre-flight days
    private static func dayLabelForPreFlight(daysRemaining: Int) -> String {
        if daysRemaining == 1 {
            return "1 day before"
        }
        return "\(daysRemaining) days before"
    }
}
