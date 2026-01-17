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
    
    var body: some View {
        NavigationStack {
            Group {
                if familyMembers.isEmpty {
                    noFamilyState
                } else if currentTrip == nil {
                    noTripState
                } else {
                    scheduleTimeline
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
    
    private var scheduleTimeline: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip summary header
                if let trip = currentTrip {
                    TripSummaryHeader(trip: trip)
                        .padding(.horizontal)
                }
                
                // Family member schedules
                ForEach(schedules) { schedule in
                    FamilyMemberTimelineRow(schedule: schedule)
                }
            }
            .padding(.vertical)
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

// MARK: - Family Member Timeline Row

struct FamilyMemberTimelineRow: View {
    let schedule: FamilyMemberSchedule
    
    @State private var expandedStages: Set<ScheduleStage> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Member header
            memberHeader
                .padding(.horizontal)
            
            // Grouped by stage
            ForEach(schedule.schedulesByStage, id: \.stage) { group in
                TripPhaseSection(
                    stage: group.stage,
                    schedules: group.schedules,
                    isExpanded: expandedStages.contains(group.stage) || shouldAutoExpand(group.stage)
                ) {
                    expandedStages.formSymmetricDifference([group.stage])
                }
            }
        }
    }
    
    private var memberHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: schedule.member.ageGroupIcon)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.member.name)
                    .font(.headline)
                Text("\(schedule.member.age) years old • \(schedule.member.adjustmentIncrement) min shifts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func shouldAutoExpand(_ stage: ScheduleStage) -> Bool {
        // Auto-expand stages with schedules for today or in the next few days
        let today = Date()
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: today) ?? today
        
        return schedule.schedulesByStage.first { $0.stage == stage }?.schedules.contains { schedule in
            schedule.date >= today && schedule.date <= threeDaysFromNow
        } ?? false
    }
}

// MARK: - Trip Phase Section

struct TripPhaseSection: View {
    let stage: ScheduleStage
    let schedules: [DailySchedule]
    let isExpanded: Bool
    let onToggle: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: stage.icon)
                        .font(.caption)
                        .foregroundStyle(stage.color)
                    
                    Text(stage.sectionTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(stage.color)
                    
                    Text("(\(schedules.count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Collapse indicator for long sections
                    if schedules.count > 3 {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
            
            // Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    let displaySchedules = isExpanded ? schedules : Array(schedules.prefix(5))
                    
                    ForEach(Array(displaySchedules.enumerated()), id: \.element.id) { index, daily in
                        TimelineCardView(schedule: daily)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.05),
                                value: appeared
                            )
                    }
                    
                    // "More" indicator
                    if !isExpanded && schedules.count > 5 {
                        moreIndicator
                    }
                }
                .padding(.horizontal)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
    
    private var moreIndicator: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("+\(schedules.count - 5) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 120)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: [FamilyMember.self, Trip.self], inMemory: true)
}
