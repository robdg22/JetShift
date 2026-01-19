//
//  ScheduleView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Query(sort: \FamilyMember.createdAt) private var familyMembers: [FamilyMember]
    @Query private var trips: [Trip]
    
    private var currentTrip: Trip? {
        trips.first
    }
    
    private var schedules: [FamilyMemberSchedule] {
        guard let trip = currentTrip else { return [] }
        return familyMembers.map { member in
            let dailySchedules = JetLagCalculator.calculateSchedule(for: member, trip: trip)
            return FamilyMemberSchedule(member: member, dailySchedules: dailySchedules)
        }
    }
    
    /// All unique dates across all family members, sorted
    private var allDates: [Date] {
        var dateSet = Set<Date>()
        for schedule in schedules {
            for daily in schedule.dailySchedules {
                // Normalize to start of day for comparison
                let normalized = Calendar.current.startOfDay(for: daily.date)
                dateSet.insert(normalized)
            }
        }
        return dateSet.sorted()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if familyMembers.isEmpty {
                    noFamilyState
                } else if currentTrip == nil {
                    noTripState
                } else {
                    scheduleTable
                }
            }
            .navigationTitle("Schedule")
        }
    }
    
    private var noFamilyState: some View {
        ContentUnavailableView {
            Label("No Family Members", systemImage: "person.3")
        } description: {
            Text("Add family members in the Family tab to generate schedules.")
        }
    }
    
    private var noTripState: some View {
        ContentUnavailableView {
            Label("No Trip Added", systemImage: "airplane")
        } description: {
            Text("Add trip details in the Trip tab to generate schedules.")
        }
    }
    
    private var scheduleTable: some View {
        VStack(spacing: 0) {
            // Trip summary header
            if let trip = currentTrip {
                TripSummaryHeader(trip: trip)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)
            }
            
            // Table
            ScheduleTableView(
                schedules: schedules,
                dates: allDates
            )
        }
        .animation(.smooth, value: schedules.count)
    }
}

// MARK: - Trip Summary Header

struct TripSummaryHeader: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.headline)
                    
                    Text(trip.tripSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !trip.dateRange.isEmpty {
                        Text(trip.dateRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Strategy badge
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: trip.strategy.icon)
                        .font(.title2)
                        .foregroundStyle(trip.strategy.color)
                    
                    Text(trip.strategy.displayName)
                        .font(.caption)
                        .foregroundStyle(trip.strategy.color)
                }
            }
            
            // Trip details
            HStack(spacing: 16) {
                Label("\(abs(trip.timezoneOffset))h shift", systemImage: "globe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if trip.hasReturnFlight {
                    Label("\(trip.daysAtDestination) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Label(trip.travelDirection.description, systemImage: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Schedule Table View

struct ScheduleTableView: View {
    let schedules: [FamilyMemberSchedule]
    let dates: [Date]
    
    @State private var selectedDate: Date?
    
    private let memberColumnWidth: CGFloat = 100
    private let cellWidth: CGFloat = 90
    private let cellHeight: CGFloat = 76
    private let headerHeight: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header row (dates)
                    headerRow
                    
                    Divider()
                    
                    // Family member rows
                    ForEach(schedules) { memberSchedule in
                        memberRow(memberSchedule)
                        
                        if memberSchedule.id != schedules.last?.id {
                            Divider()
                                .padding(.leading, memberColumnWidth)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Empty corner cell for member names
                Text("")
                    .frame(width: memberColumnWidth, height: headerHeight)
                    .background(.ultraThinMaterial)
                
                // Date headers
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    dateHeader(for: date, at: index)
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }
    
    private func dateHeader(for date: Date, at index: Int) -> some View {
        let schedule = findSchedule(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        
        return VStack(spacing: 2) {
            // Day label
            Text(schedule?.dayLabel ?? "")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(schedule?.stage.color ?? .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Date
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .primary : .secondary)
            
            // Stage indicator dot
            Circle()
                .fill(schedule?.stage.color ?? .gray)
                .frame(width: 6, height: 6)
        }
        .frame(width: cellWidth, height: headerHeight)
        .background(isToday ? Color.accentColor.opacity(0.1) : Color.clear)
        .overlay(alignment: .top) {
            if isToday {
                Text("TODAY")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.accentColor, in: Capsule())
                    .offset(y: -2)
            }
        }
    }
    
    // MARK: - Member Row
    
    private func memberRow(_ memberSchedule: FamilyMemberSchedule) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Member name column (sticky in spirit, but scrolls with row)
                memberNameCell(memberSchedule.member)
                
                // Schedule cells for each date
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    if let daily = memberSchedule.dailySchedules.first(where: {
                        Calendar.current.isDate($0.date, inSameDayAs: date)
                    }) {
                        scheduleCell(daily, isToday: Calendar.current.isDateInToday(date))
                    } else {
                        emptyCell(isToday: Calendar.current.isDateInToday(date))
                    }
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }
    
    private func memberNameCell(_ member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: member.ageGroupIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(member.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            // Show custom strategy indicator
            if member.usesCustomStrategy, let strategy = member.customStrategy {
                HStack(spacing: 2) {
                    Image(systemName: strategy.icon)
                        .font(.system(size: 8))
                    Text(strategy.shortDisplayName)
                        .font(.system(size: 8))
                }
                .foregroundStyle(strategy.color)
            }
        }
        .frame(width: memberColumnWidth, height: cellHeight, alignment: .leading)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
    }
    
    private func scheduleCell(_ schedule: DailySchedule, isToday: Bool) -> some View {
        VStack(spacing: 4) {
            // Body clock offset (compact)
            bodyClockBadge(schedule)
            
            // Bedtime
            HStack(spacing: 3) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.blue)
                Text(schedule.formattedBedtime)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
            
            // Wake time
            HStack(spacing: 3) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.orange)
                Text(schedule.formattedWakeTime)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .background(
            isToday
                ? Color.accentColor.opacity(0.08)
                : schedule.stage.color.opacity(0.05)
        )
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
            }
        }
    }
    
    private func bodyClockBadge(_ schedule: DailySchedule) -> some View {
        let color = bodyClockColor(for: schedule)
        
        return HStack(spacing: 2) {
            Image(systemName: bodyClockIcon(for: schedule))
                .font(.system(size: 7))
            Text(compactBodyClockOffset(schedule))
                .font(.system(size: 8, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(color.opacity(0.15), in: Capsule())
    }
    
    private func emptyCell(isToday: Bool) -> some View {
        Text("—")
            .font(.caption)
            .foregroundStyle(.quaternary)
            .frame(width: cellWidth, height: cellHeight)
            .background(isToday ? Color.accentColor.opacity(0.08) : Color.clear)
    }
    
    // MARK: - Helpers
    
    private func findSchedule(for date: Date) -> DailySchedule? {
        for memberSchedule in schedules {
            if let daily = memberSchedule.dailySchedules.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }) {
                return daily
            }
        }
        return nil
    }
    
    private func compactBodyClockOffset(_ schedule: DailySchedule) -> String {
        if schedule.isInSync {
            return "✓"
        }
        let hours = Double(schedule.bodyClockOffsetMinutes) / 60.0
        let sign = hours > 0 ? "+" : ""
        return String(format: "%@%.0fh", sign, hours)
    }
    
    private func bodyClockIcon(for schedule: DailySchedule) -> String {
        if schedule.isInSync {
            return "checkmark.circle.fill"
        } else if schedule.bodyClockOffsetMinutes > 0 {
            return "arrow.forward"
        } else {
            return "arrow.backward"
        }
    }
    
    private func bodyClockColor(for schedule: DailySchedule) -> Color {
        if schedule.isInSync {
            return .green
        }
        let absOffset = abs(schedule.bodyClockOffsetMinutes)
        if absOffset <= 60 {
            return .green
        } else if absOffset <= 180 {
            return .yellow
        } else {
            return .red
        }
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: [FamilyMember.self, Trip.self], inMemory: true)
}
