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
    
    /// Number of post-arrival days
    static let postArrivalDays = 2
    
    /// Calculate the complete adjustment schedule for a family member
    /// - Parameters:
    ///   - member: The family member to calculate for
    ///   - flight: The flight details
    /// - Returns: Array of daily schedules covering pre-flight, travel day, and post-arrival
    static func calculateSchedule(for member: FamilyMember, flight: Flight) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let calendar = Calendar.current
        
        let timezoneOffset = flight.timezoneOffset
        let direction = flight.travelDirection
        let increment = member.adjustmentIncrement
        let travelDate = flight.departureDate
        
        // Pre-flight adjustment days (3 days before)
        for dayOffset in (-preFlightDays)...(-1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: travelDate) else {
                continue
            }
            
            let adjustmentDays = preFlightDays + dayOffset + 1 // 1, 2, 3 days of adjustment
            let totalMinutes = adjustmentDays * increment
            
            let adjustedBedtime: Date
            let adjustedWakeTime: Date
            
            switch direction {
            case .east:
                // Eastward travel: shift earlier (subtract time)
                adjustedBedtime = adjustTime(member.currentBedtime, byMinutes: -totalMinutes)
                adjustedWakeTime = adjustTime(member.currentWakeTime, byMinutes: -totalMinutes)
            case .west:
                // Westward travel: shift later (add time)
                adjustedBedtime = adjustTime(member.currentBedtime, byMinutes: totalMinutes)
                adjustedWakeTime = adjustTime(member.currentWakeTime, byMinutes: totalMinutes)
            case .none:
                // No timezone change: keep original times
                adjustedBedtime = member.currentBedtime
                adjustedWakeTime = member.currentWakeTime
            }
            
            let dayLabel = dayLabelForPreFlight(daysRemaining: abs(dayOffset))
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: dayLabel,
                bedtime: adjustedBedtime,
                wakeTime: adjustedWakeTime,
                stage: .preAdjustment
            ))
        }
        
        // Travel day (Day 0)
        let destinationBedtime = convertToDestinationTime(
            member.currentBedtime,
            from: flight.departureTimezone,
            to: flight.arrivalTimezone
        )
        let destinationWakeTime = convertToDestinationTime(
            member.currentWakeTime,
            from: flight.departureTimezone,
            to: flight.arrivalTimezone
        )
        
        schedules.append(DailySchedule(
            date: travelDate,
            dayLabel: "Travel Day",
            bedtime: destinationBedtime,
            wakeTime: destinationWakeTime,
            stage: .travelDay
        ))
        
        // Post-arrival days (Days 1-2)
        for dayOffset in 1...postArrivalDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: travelDate) else {
                continue
            }
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: "Day \(dayOffset)",
                bedtime: destinationBedtime,
                wakeTime: destinationWakeTime,
                stage: .postArrival
            ))
        }
        
        return schedules
    }
    
    /// Adjust a time by a specified number of minutes
    private static func adjustTime(_ time: Date, byMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .minute, value: minutes, to: time) ?? time
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
        
        // Calculate the offset difference
        let sourceOffset = sourceTZ.secondsFromGMT(for: time)
        let destOffset = destTZ.secondsFromGMT(for: time)
        let difference = destOffset - sourceOffset
        
        // Adjust the time by the difference
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
