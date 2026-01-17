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
    @Query private var flights: [Flight]
    
    private var currentFlight: Flight? {
        flights.first
    }
    
    private var schedules: [FamilyMemberSchedule] {
        guard let flight = currentFlight else { return [] }
        return familyMembers.map { member in
            let dailySchedules = JetLagCalculator.calculateSchedule(for: member, flight: flight)
            return FamilyMemberSchedule(member: member, dailySchedules: dailySchedules)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if familyMembers.isEmpty {
                    noFamilyState
                } else if currentFlight == nil {
                    noFlightState
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
    
    private var noFlightState: some View {
        ContentUnavailableView {
            Label("No Flight Added", systemImage: "airplane")
        } description: {
            Text("Add flight details in the Flight tab to generate schedules.")
        }
    }
    
    private var scheduleTimeline: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(schedules) { schedule in
                    FamilyMemberTimelineRow(schedule: schedule)
                }
            }
            .padding()
        }
        .animation(.smooth, value: schedules.count)
    }
}

struct FamilyMemberTimelineRow: View {
    let schedule: FamilyMemberSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Member header
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
            }
            
            // Timeline cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(schedule.dailySchedules) { daily in
                        TimelineCardView(schedule: daily)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: [FamilyMember.self, Flight.self], inMemory: true)
}
