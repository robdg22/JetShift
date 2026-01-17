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
    
    /// Number of pre-return adjustment days
    static let preReturnDays = 2
    
    /// Number of post-return recovery days
    static let postReturnDays = 3
    
    /// Buffer time (in hours) from flight arrival to hotel check-in
    static let hotelArrivalBufferHours = 2
    
    /// Late bedtime hour for "stay up late" strategy (westward)
    static let stayUpLateBedtimeHour = 23 // 11 PM
    
    /// Target bedtime hour for eastward travel day
    static let eastwardTargetBedtimeHour = 22 // 10 PM
    
    // MARK: - Main Calculation Entry Point
    
    /// Calculate the complete adjustment schedule for a family member based on trip
    /// - Parameters:
    ///   - member: The family member to calculate for
    ///   - trip: The trip with flights and strategy
    /// - Returns: Array of daily schedules for the full trip arc
    static func calculateSchedule(for member: FamilyMember, trip: Trip) -> [DailySchedule] {
        guard let outbound = trip.outboundFlight else { return [] }
        
        var schedules: [DailySchedule] = []
        let calendar = Calendar.current
        
        // Use member's custom strategy if set, otherwise trip default
        let strategy = member.effectiveStrategy(tripDefault: trip.strategy)
        
        // No adjustment strategy - just show travel days with no schedule changes
        if case .noAdjustment = strategy {
            return calculateNoAdjustmentSchedule(for: member, trip: trip, calendar: calendar)
        }
        
        // Note: adjustmentPercentage is used within individual calculation methods
        
        // 1. Pre-outbound adjustment
        schedules.append(contentsOf: calculatePreFlightSchedules(
            for: member,
            flight: outbound,
            strategy: strategy,
            calendar: calendar
        ))
        
        // 2. Outbound travel day
        schedules.append(calculateTravelDaySchedule(
            for: member,
            flight: outbound,
            strategy: strategy,
            isReturn: false,
            calendar: calendar
        ))
        
        // 3. At destination days
        if let returnFlight = trip.returnFlight {
            schedules.append(contentsOf: calculateAtDestinationSchedules(
                for: member,
                outbound: outbound,
                returnFlight: returnFlight,
                strategy: strategy,
                calendar: calendar
            ))
            
            // 4. Pre-return adjustment (Minimize Total strategy)
            if case .minimizeTotal = strategy {
                schedules.append(contentsOf: calculatePreReturnSchedules(
                    for: member,
                    outbound: outbound,
                    returnFlight: returnFlight,
                    calendar: calendar
                ))
            }
            
            // 5. Return travel day
            schedules.append(calculateTravelDaySchedule(
                for: member,
                flight: returnFlight,
                strategy: strategy,
                isReturn: true,
                calendar: calendar
            ))
            
            // 6. Post-return recovery
            schedules.append(contentsOf: calculatePostReturnSchedules(
                for: member,
                returnFlight: returnFlight,
                strategy: strategy,
                originalOutbound: outbound,
                calendar: calendar
            ))
        } else {
            // No return flight - just post-arrival adjustment
            schedules.append(contentsOf: calculatePostArrivalSchedules(
                for: member,
                flight: outbound,
                strategy: strategy,
                calendar: calendar
            ))
        }
        
        return schedules
    }
    
    // MARK: - No Adjustment Strategy
    
    private static func calculateNoAdjustmentSchedule(
        for member: FamilyMember,
        trip: Trip,
        calendar: Calendar
    ) -> [DailySchedule] {
        guard let outbound = trip.outboundFlight else { return [] }
        
        var schedules: [DailySchedule] = []
        
        // Just travel days with strategy message
        schedules.append(DailySchedule(
            date: outbound.departureDate,
            dayLabel: "Travel Day",
            bedtime: member.currentBedtime,
            wakeTime: member.currentWakeTime,
            stage: .travelDayOutbound,
            strategyMessage: "Stay on home time",
            travelDirection: outbound.travelDirection,
            bodyClockOffsetMinutes: 0
        ))
        
        if let returnFlight = trip.returnFlight {
            // Days at destination - maintain home schedule
            let daysAtDest = max(1, trip.daysAtDestination - 1)
            for day in 1...min(daysAtDest, 14) { // Cap at 14 days to avoid huge lists
                guard let date = calendar.date(byAdding: .day, value: day, to: outbound.departureDate) else { continue }
                
                schedules.append(DailySchedule(
                    date: date,
                    dayLabel: "Day \(day)",
                    bedtime: member.currentBedtime,
                    wakeTime: member.currentWakeTime,
                    stage: .atDestination,
                    strategyMessage: "Maintain home time schedule",
                    travelDirection: outbound.travelDirection,
                    bodyClockOffsetMinutes: 0
                ))
            }
            
            schedules.append(DailySchedule(
                date: returnFlight.departureDate,
                dayLabel: "Return",
                bedtime: member.currentBedtime,
                wakeTime: member.currentWakeTime,
                stage: .travelDayReturn,
                strategyMessage: "No adjustment needed",
                travelDirection: returnFlight.travelDirection,
                bodyClockOffsetMinutes: 0
            ))
        }
        
        return schedules
    }
    
    // MARK: - Pre-Flight Calculation
    
    private static func calculatePreFlightSchedules(
        for member: FamilyMember,
        flight: FlightDetails,
        strategy: TripStrategy,
        calendar: Calendar
    ) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let direction = flight.travelDirection
        let increment = member.adjustmentIncrement
        let travelDate = flight.departureDate
        
        // Target adjustment based on strategy
        let adjustmentPercentage = strategy.adjustmentPercentage
        let totalTimezoneOffsetMinutes = abs(flight.timezoneOffset) * 60
        let targetAdjustmentMinutes = Int(Double(totalTimezoneOffsetMinutes) * adjustmentPercentage)
        
        for dayOffset in (-preFlightDays)...(-1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: travelDate) else {
                continue
            }
            
            let adjustmentDays = preFlightDays + dayOffset + 1 // 1, 2, 3 days of adjustment
            let totalAdjustedMinutes = min(adjustmentDays * increment, targetAdjustmentMinutes)
            
            let adjustedBedtime: Date
            let adjustedWakeTime: Date
            
            var proposedBedtime: Date
            var proposedWakeTime: Date
            
            switch direction {
            case .east:
                // Eastward travel: shift earlier (waking earlier is fine for constraint)
                proposedBedtime = adjustTime(member.currentBedtime, byMinutes: -totalAdjustedMinutes)
                proposedWakeTime = adjustTime(member.currentWakeTime, byMinutes: -totalAdjustedMinutes)
            case .west:
                // Westward travel: shift later (might violate wake constraint)
                proposedBedtime = adjustTime(member.currentBedtime, byMinutes: totalAdjustedMinutes)
                proposedWakeTime = adjustTime(member.currentWakeTime, byMinutes: totalAdjustedMinutes)
            case .none:
                proposedBedtime = member.currentBedtime
                proposedWakeTime = member.currentWakeTime
            }
            
            // Apply wake constraint (clamp wake time if it exceeds work/school requirement)
            let clampedWakeTime = clampToWakeConstraint(wakeTime: proposedWakeTime, member: member, calendar: calendar)
            let finalBedtime = adjustBedtimeForClampedWake(
                originalBedtime: proposedBedtime,
                originalWakeTime: proposedWakeTime,
                clampedWakeTime: clampedWakeTime,
                member: member,
                calendar: calendar
            )
            
            adjustedBedtime = finalBedtime
            adjustedWakeTime = clampedWakeTime
            
            // Body clock offset
            let remainingOffset = targetAdjustmentMinutes - totalAdjustedMinutes
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
                dayLabel: dayLabelForPreFlight(daysRemaining: abs(dayOffset)),
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
        flight: FlightDetails,
        strategy: TripStrategy,
        isReturn: Bool,
        calendar: Calendar
    ) -> DailySchedule {
        let direction = flight.travelDirection
        let travelDate = flight.departureDate
        
        // Hotel arrival time
        let hotelArrival = calendar.date(
            byAdding: .hour,
            value: hotelArrivalBufferHours,
            to: flight.arrivalTime
        ) ?? flight.arrivalTime
        
        // Strategy message and targets
        let strategyMessage: String
        let targetBedtime: Date
        let targetWakeTime: Date
        
        let stage: ScheduleStage = isReturn ? .travelDayReturn : .travelDayOutbound
        
        switch direction {
        case .west:
            strategyMessage = "Stay up as late as possible"
            targetBedtime = createTime(hour: stayUpLateBedtimeHour, minute: 0, from: travelDate, calendar: calendar)
            targetWakeTime = createTime(hour: 8, minute: 0, from: travelDate, calendar: calendar)
            
        case .east:
            strategyMessage = "Short morning nap if tired, then stay awake as long as possible"
            targetBedtime = createTime(hour: eastwardTargetBedtimeHour, minute: 0, from: travelDate, calendar: calendar)
            targetWakeTime = createTime(hour: 7, minute: 0, from: travelDate, calendar: calendar)
            
        case .none:
            strategyMessage = "Maintain regular schedule"
            targetBedtime = member.currentBedtime
            targetWakeTime = member.currentWakeTime
        }
        
        // Body clock offset estimate
        let preFlightAdjustment = preFlightDays * member.adjustmentIncrement
        let totalOffset = abs(flight.timezoneOffset) * 60
        let remainingOffset = max(0, totalOffset - preFlightAdjustment)
        let bodyClockOffset = direction == .east ? -remainingOffset : remainingOffset
        
        return DailySchedule(
            date: travelDate,
            dayLabel: isReturn ? "Return Flight" : "Travel Day",
            bedtime: targetBedtime,
            wakeTime: targetWakeTime,
            stage: stage,
            strategyMessage: strategyMessage,
            hotelArrival: isReturn ? nil : hotelArrival,
            travelDirection: direction,
            bodyClockOffsetMinutes: direction == .none ? 0 : bodyClockOffset
        )
    }
    
    // MARK: - At Destination Calculation
    
    private static func calculateAtDestinationSchedules(
        for member: FamilyMember,
        outbound: FlightDetails,
        returnFlight: FlightDetails,
        strategy: TripStrategy,
        calendar: Calendar
    ) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let direction = outbound.travelDirection
        let increment = member.adjustmentIncrement
        
        // Calculate days at destination (excluding travel days)
        let daysAtDestination = calendar.dateComponents([.day], from: outbound.departureDate, to: returnFlight.departureDate).day ?? 0
        
        // For minimize total, we need to leave room for pre-return days
        let preReturnDaysNeeded = (strategy == .minimizeTotal) ? preReturnDays : 0
        let postArrivalDaysToShow = min(postArrivalDays, max(1, daysAtDestination - preReturnDaysNeeded - 1))
        
        let adjustmentPercentage = strategy.adjustmentPercentage
        let totalTimezoneOffsetMinutes = abs(outbound.timezoneOffset) * 60
        let targetAdjustmentMinutes = Int(Double(totalTimezoneOffsetMinutes) * adjustmentPercentage)
        let preFlightAdjustment = min(preFlightDays * increment, targetAdjustmentMinutes)
        
        // Post-arrival adjustment days (gradual adjustment to target)
        // 
        // WESTBOUND: Body clock is AHEAD of local time
        //   - You'll wake up too EARLY (body thinks it's later than it is)
        //   - You'll feel sleepy too EARLY in the evening
        //   - Strategy: Show early wake times that progress LATER toward normal
        //   - Bedtime: Keep it at target (encourage staying up)
        //
        // EASTBOUND: Body clock is BEHIND local time
        //   - You'll want to sleep too LATE (body thinks it's earlier than it is)
        //   - You'll want to wake too LATE in the morning
        //   - Strategy: Show earlier bedtimes that progress LATER toward normal
        //   - Wake time: Keep at target (force early waking)
        
        for dayOffset in 1...postArrivalDaysToShow {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: outbound.departureDate) else { continue }
            
            let postArrivalAdjustment = min(dayOffset * increment, targetAdjustmentMinutes - preFlightAdjustment)
            let totalAdjusted = preFlightAdjustment + postArrivalAdjustment
            let remainingOffsetMinutes = max(0, targetAdjustmentMinutes - totalAdjusted)
            
            var adjustedBedtime: Date
            var adjustedWakeTime: Date
            
            // Get the member's normal/target times
            let normalBedtimeHour = Calendar.current.component(.hour, from: member.currentBedtime)
            let normalBedtimeMinute = Calendar.current.component(.minute, from: member.currentBedtime)
            let normalWakeHour = Calendar.current.component(.hour, from: member.currentWakeTime)
            let normalWakeMinute = Calendar.current.component(.minute, from: member.currentWakeTime)
            
            let targetBedtime = createTime(hour: normalBedtimeHour, minute: normalBedtimeMinute, from: date, calendar: calendar)
            let targetWakeTime = createTime(hour: normalWakeHour, minute: normalWakeMinute, from: date, calendar: calendar)
            
            switch direction {
            case .west:
                // WESTBOUND: Body wakes EARLY, sleeps EARLY
                // Wake time: Start early (body wakes you), progress LATER toward normal
                // Bedtime: Stay at normal (encourage staying up late)
                let earlyWakeOffset = remainingOffsetMinutes  // How early body will wake
                adjustedWakeTime = adjustTime(targetWakeTime, byMinutes: -earlyWakeOffset)
                adjustedBedtime = targetBedtime  // Try to stay up until normal bedtime
                
            case .east:
                // EASTBOUND: Body wakes LATE, sleeps LATE  
                // Bedtime: Start early (force sleep), progress LATER toward normal
                // Wake time: Stay at normal (force early waking with alarm)
                let earlyBedOffset = remainingOffsetMinutes  // How much earlier to go to bed
                adjustedBedtime = adjustTime(targetBedtime, byMinutes: -earlyBedOffset)
                adjustedWakeTime = targetWakeTime  // Wake at target time
                
            case .none:
                adjustedBedtime = targetBedtime
                adjustedWakeTime = targetWakeTime
            }
            
            // Apply wake constraint
            let clampedWakeTime = clampToWakeConstraint(wakeTime: adjustedWakeTime, member: member, calendar: calendar)
            let finalBedtime = adjustBedtimeForClampedWake(
                originalBedtime: adjustedBedtime,
                originalWakeTime: adjustedWakeTime,
                clampedWakeTime: clampedWakeTime,
                member: member,
                calendar: calendar
            )
            
            // Body clock offset (positive = ahead of local, negative = behind)
            let bodyClockOffset = direction == .east ? -remainingOffsetMinutes : remainingOffsetMinutes
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: "Day \(dayOffset)",
                bedtime: finalBedtime,
                wakeTime: clampedWakeTime,
                stage: .atDestination,
                travelDirection: direction,
                bodyClockOffsetMinutes: direction == .none ? 0 : bodyClockOffset
            ))
        }
        
        // Additional days at destination (maintaining schedule)
        let maintainedDays = daysAtDestination - postArrivalDaysToShow - preReturnDaysNeeded - 1
        if maintainedDays > 0 {
            let finalBedtime = schedules.last?.bedtime ?? member.currentBedtime
            let finalWakeTime = schedules.last?.wakeTime ?? member.currentWakeTime
            
            for dayOffset in (postArrivalDaysToShow + 1)...(postArrivalDaysToShow + min(maintainedDays, 7)) {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: outbound.departureDate) else { continue }
                
                schedules.append(DailySchedule(
                    date: date,
                    dayLabel: "Day \(dayOffset)",
                    bedtime: finalBedtime,
                    wakeTime: finalWakeTime,
                    stage: .atDestination,
                    travelDirection: direction,
                    bodyClockOffsetMinutes: 0 // Fully adjusted at this point
                ))
            }
        }
        
        return schedules
    }
    
    // MARK: - Pre-Return Calculation (Minimize Total Strategy)
    
    private static func calculatePreReturnSchedules(
        for member: FamilyMember,
        outbound: FlightDetails,
        returnFlight: FlightDetails,
        calendar: Calendar
    ) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let direction = outbound.travelDirection
        let increment = member.adjustmentIncrement
        
        // Shift back toward home timezone
        for dayOffset in (-preReturnDays)...(-1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: returnFlight.departureDate) else { continue }
            
            let daysShifting = preReturnDays + dayOffset + 1
            let shiftBackMinutes = daysShifting * increment
            
            // Get last destination schedule time as starting point
            let startBedtime: Date
            let startWakeTime: Date
            
            switch direction {
            case .west:
                // Was on later schedule, shifting back earlier
                startBedtime = createTime(hour: 22, minute: 0, from: date, calendar: calendar)
                startWakeTime = createTime(hour: 6, minute: 30, from: date, calendar: calendar)
            case .east:
                // Was on earlier schedule, shifting back later
                startBedtime = createTime(hour: 21, minute: 0, from: date, calendar: calendar)
                startWakeTime = createTime(hour: 5, minute: 30, from: date, calendar: calendar)
            case .none:
                startBedtime = member.currentBedtime
                startWakeTime = member.currentWakeTime
            }
            
            let adjustedBedtime: Date
            let adjustedWakeTime: Date
            
            switch direction {
            case .west:
                // Shifting earlier
                adjustedBedtime = adjustTime(startBedtime, byMinutes: shiftBackMinutes)
                adjustedWakeTime = adjustTime(startWakeTime, byMinutes: shiftBackMinutes)
            case .east:
                // Shifting later
                adjustedBedtime = adjustTime(startBedtime, byMinutes: shiftBackMinutes)
                adjustedWakeTime = adjustTime(startWakeTime, byMinutes: shiftBackMinutes)
            case .none:
                adjustedBedtime = member.currentBedtime
                adjustedWakeTime = member.currentWakeTime
            }
            
            let totalOffset = abs(outbound.timezoneOffset) * 60
            let remainingOffset = max(0, totalOffset - shiftBackMinutes)
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: "\(abs(dayOffset)) day\(abs(dayOffset) == 1 ? "" : "s") before return",
                bedtime: adjustedBedtime,
                wakeTime: adjustedWakeTime,
                stage: .preReturn,
                travelDirection: direction,
                bodyClockOffsetMinutes: direction == .east ? remainingOffset : -remainingOffset
            ))
        }
        
        return schedules
    }
    
    // MARK: - Post-Arrival Calculation (No Return Flight)
    
    private static func calculatePostArrivalSchedules(
        for member: FamilyMember,
        flight: FlightDetails,
        strategy: TripStrategy,
        calendar: Calendar
    ) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let direction = flight.travelDirection
        let increment = member.adjustmentIncrement
        let travelDate = flight.departureDate
        
        let adjustmentPercentage = strategy.adjustmentPercentage
        let totalTimezoneOffsetMinutes = abs(flight.timezoneOffset) * 60
        let targetAdjustmentMinutes = Int(Double(totalTimezoneOffsetMinutes) * adjustmentPercentage)
        let preFlightAdjustment = min(preFlightDays * increment, targetAdjustmentMinutes)
        
        for dayOffset in 1...postArrivalDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: travelDate) else { continue }
            
            let postArrivalAdjustment = min(dayOffset * increment, targetAdjustmentMinutes - preFlightAdjustment)
            let totalAdjusted = preFlightAdjustment + postArrivalAdjustment
            let remainingOffsetMinutes = max(0, targetAdjustmentMinutes - totalAdjusted)
            
            var adjustedBedtime: Date
            var adjustedWakeTime: Date
            
            // Get the member's normal/target times
            let normalBedtimeHour = Calendar.current.component(.hour, from: member.currentBedtime)
            let normalBedtimeMinute = Calendar.current.component(.minute, from: member.currentBedtime)
            let normalWakeHour = Calendar.current.component(.hour, from: member.currentWakeTime)
            let normalWakeMinute = Calendar.current.component(.minute, from: member.currentWakeTime)
            
            let targetBedtime = createTime(hour: normalBedtimeHour, minute: normalBedtimeMinute, from: date, calendar: calendar)
            let targetWakeTime = createTime(hour: normalWakeHour, minute: normalWakeMinute, from: date, calendar: calendar)
            
            switch direction {
            case .west:
                // WESTBOUND: Body wakes EARLY, sleeps EARLY
                // Wake time: Start early, progress LATER toward normal
                // Bedtime: Stay at normal (encourage staying up)
                adjustedWakeTime = adjustTime(targetWakeTime, byMinutes: -remainingOffsetMinutes)
                adjustedBedtime = targetBedtime
                
            case .east:
                // EASTBOUND: Body wakes LATE, sleeps LATE
                // Bedtime: Start early, progress LATER toward normal
                // Wake time: Stay at normal
                adjustedBedtime = adjustTime(targetBedtime, byMinutes: -remainingOffsetMinutes)
                adjustedWakeTime = targetWakeTime
                
            case .none:
                adjustedBedtime = targetBedtime
                adjustedWakeTime = targetWakeTime
            }
            
            // Apply wake constraint
            let clampedWakeTime = clampToWakeConstraint(wakeTime: adjustedWakeTime, member: member, calendar: calendar)
            let finalBedtime = adjustBedtimeForClampedWake(
                originalBedtime: adjustedBedtime,
                originalWakeTime: adjustedWakeTime,
                clampedWakeTime: clampedWakeTime,
                member: member,
                calendar: calendar
            )
            
            let bodyClockOffset = direction == .east ? -remainingOffsetMinutes : remainingOffsetMinutes
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: "Day \(dayOffset)",
                bedtime: finalBedtime,
                wakeTime: clampedWakeTime,
                stage: .postArrival,
                travelDirection: direction,
                bodyClockOffsetMinutes: direction == .none ? 0 : bodyClockOffset
            ))
        }
        
        return schedules
    }
    
    // MARK: - Post-Return Calculation
    
    private static func calculatePostReturnSchedules(
        for member: FamilyMember,
        returnFlight: FlightDetails,
        strategy: TripStrategy,
        originalOutbound: FlightDetails,
        calendar: Calendar
    ) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        let increment = member.adjustmentIncrement
        let returnDate = returnFlight.departureDate
        
        // Recovery days depend on strategy
        let recoveryDays = TripRecommendationEngine.estimatedRecoveryDays(
            for: strategy,
            timezoneOffset: originalOutbound.timezoneOffset
        )
        
        let actualRecoveryDays = max(1, min(recoveryDays, postReturnDays))
        
        for dayOffset in 1...actualRecoveryDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: returnDate) else { continue }
            
            let recoveryProgress = min(dayOffset * increment, abs(originalOutbound.timezoneOffset) * 60)
            
            // Gradual return to normal home schedule
            let remainingAdjustment = Int((1.0 - Double(dayOffset) / Double(actualRecoveryDays)) * Double(increment))
            let proposedBedtime = adjustTime(member.currentBedtime, byMinutes: remainingAdjustment)
            let proposedWakeTime = adjustTime(member.currentWakeTime, byMinutes: remainingAdjustment)
            
            // Apply wake constraint (critical for post-return as person needs to get to work/school)
            let clampedWakeTime = clampToWakeConstraint(wakeTime: proposedWakeTime, member: member, calendar: calendar)
            let finalBedtime = adjustBedtimeForClampedWake(
                originalBedtime: proposedBedtime,
                originalWakeTime: proposedWakeTime,
                clampedWakeTime: clampedWakeTime,
                member: member,
                calendar: calendar
            )
            
            let remainingOffset = max(0, abs(originalOutbound.timezoneOffset) * 60 - recoveryProgress)
            
            schedules.append(DailySchedule(
                date: date,
                dayLabel: "Recovery Day \(dayOffset)",
                bedtime: finalBedtime,
                wakeTime: clampedWakeTime,
                stage: .postReturn,
                travelDirection: returnFlight.travelDirection,
                bodyClockOffsetMinutes: remainingOffset
            ))
        }
        
        return schedules
    }
    
    // MARK: - Helper Methods
    
    private static func adjustTime(_ time: Date, byMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .minute, value: minutes, to: time) ?? time
    }
    
    private static func createTime(hour: Int, minute: Int, from date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? date
    }
    
    private static func dayLabelForPreFlight(daysRemaining: Int) -> String {
        if daysRemaining == 1 {
            return "1 day before"
        }
        return "\(daysRemaining) days before"
    }
    
    /// Clamps wake time to not exceed the member's wake-by constraint
    /// - Parameters:
    ///   - wakeTime: The proposed wake time
    ///   - member: The family member with potential wake constraint
    ///   - calendar: Calendar for date calculations
    /// - Returns: The clamped wake time (no later than wake-by if constraint exists)
    private static func clampToWakeConstraint(
        wakeTime: Date,
        member: FamilyMember,
        calendar: Calendar
    ) -> Date {
        guard member.hasWakeConstraint else { return wakeTime }
        
        // Extract time components from both dates
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)
        let constraintComponents = calendar.dateComponents([.hour, .minute], from: member.wakeByTime)
        
        let wakeMinutes = (wakeComponents.hour ?? 0) * 60 + (wakeComponents.minute ?? 0)
        let constraintMinutes = (constraintComponents.hour ?? 0) * 60 + (constraintComponents.minute ?? 0)
        
        // If wake time is later than constraint, clamp it
        if wakeMinutes > constraintMinutes {
            // Return the constraint time on the same "day" as the wake time
            var components = calendar.dateComponents([.year, .month, .day], from: wakeTime)
            components.hour = constraintComponents.hour
            components.minute = constraintComponents.minute
            return calendar.date(from: components) ?? wakeTime
        }
        
        return wakeTime
    }
    
    /// Adjusts bedtime to maintain sleep duration when wake time is clamped
    /// - Parameters:
    ///   - originalBedtime: The originally calculated bedtime
    ///   - originalWakeTime: The originally calculated wake time
    ///   - clampedWakeTime: The wake time after constraint clamping
    ///   - member: The family member
    ///   - calendar: Calendar for date calculations
    /// - Returns: Adjusted bedtime to maintain similar sleep duration
    private static func adjustBedtimeForClampedWake(
        originalBedtime: Date,
        originalWakeTime: Date,
        clampedWakeTime: Date,
        member: FamilyMember,
        calendar: Calendar
    ) -> Date {
        // If wake wasn't clamped, return original bedtime
        let originalWakeComponents = calendar.dateComponents([.hour, .minute], from: originalWakeTime)
        let clampedWakeComponents = calendar.dateComponents([.hour, .minute], from: clampedWakeTime)
        
        let originalWakeMinutes = (originalWakeComponents.hour ?? 0) * 60 + (originalWakeComponents.minute ?? 0)
        let clampedWakeMinutes = (clampedWakeComponents.hour ?? 0) * 60 + (clampedWakeComponents.minute ?? 0)
        
        if originalWakeMinutes == clampedWakeMinutes {
            return originalBedtime
        }
        
        // Wake was clamped earlier, so shift bedtime earlier by the same amount
        let clampedByMinutes = originalWakeMinutes - clampedWakeMinutes
        return adjustTime(originalBedtime, byMinutes: -clampedByMinutes)
    }
}
