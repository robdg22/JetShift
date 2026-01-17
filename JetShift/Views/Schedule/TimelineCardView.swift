//
//  TimelineCardView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI

struct TimelineCardView: View {
    let schedule: DailySchedule
    
    @State private var tapped = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day label and date
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.dayLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(schedule.stage.color)
                
                Text(schedule.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Sleep times
            VStack(alignment: .leading, spacing: 8) {
                // Bedtime
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Bedtime")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(schedule.formattedBedtime)
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                }
                
                // Wake time
                HStack(spacing: 8) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Wake")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(schedule.formattedWakeTime)
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Stage indicator
            HStack(spacing: 4) {
                Image(systemName: schedule.stage.icon)
                    .font(.caption2)
                Text(schedule.stage.description)
                    .font(.caption2)
            }
            .foregroundStyle(schedule.stage.color)
        }
        .padding()
        .frame(width: 140)
        .glassEffect()
        .overlay {
            if schedule.isToday {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(schedule.stage.color, lineWidth: 2)
            }
        }
        .overlay(alignment: .topTrailing) {
            if schedule.isToday {
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(schedule.stage.color)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .offset(x: -8, y: 8)
            }
        }
        .animation(.easeInOut, value: schedule.isToday)
        .onTapGesture {
            tapped.toggle()
        }
        .sensoryFeedback(.selection, trigger: tapped)
    }
}

#Preview {
    HStack(spacing: 16) {
        TimelineCardView(schedule: DailySchedule(
            date: Date(),
            dayLabel: "2 days before",
            bedtime: Date(),
            wakeTime: Date(),
            stage: .preAdjustment
        ))
        
        TimelineCardView(schedule: DailySchedule(
            date: Date(),
            dayLabel: "Travel Day",
            bedtime: Date(),
            wakeTime: Date(),
            stage: .travelDay
        ))
        
        TimelineCardView(schedule: DailySchedule(
            date: Date(),
            dayLabel: "Day 1",
            bedtime: Date(),
            wakeTime: Date(),
            stage: .postArrival
        ))
    }
    .padding()
}
