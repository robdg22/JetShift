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
        VStack(alignment: .leading, spacing: 10) {
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
            
            // Body clock offset indicator
            bodyClockIndicator
            
            Divider()
            
            // Content varies based on whether it's travel day
            if schedule.hasStrategy {
                travelDayContent
            } else {
                regularDayContent
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
        .frame(width: schedule.hasStrategy ? 170 : 150)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if schedule.isToday {
                RoundedRectangle(cornerRadius: 12)
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
    
    // MARK: - Body Clock Indicator
    
    private var bodyClockIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: bodyClockIcon)
                .font(.caption2)
            Text(schedule.formattedBodyClockOffset)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(bodyClockColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(bodyClockColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var bodyClockIcon: String {
        if schedule.isInSync {
            return "checkmark.circle.fill"
        } else if schedule.bodyClockOffsetMinutes > 0 {
            return "arrow.forward.circle.fill"
        } else {
            return "arrow.backward.circle.fill"
        }
    }
    
    private var bodyClockColor: Color {
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
    
    // MARK: - Travel Day Content
    
    private var travelDayContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Strategy message
            if let strategy = schedule.strategyMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: strategyIcon)
                        .font(.subheadline)
                        .foregroundStyle(schedule.stage.color)
                    
                    Text(strategy)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Hotel arrival estimate
            if let hotelTime = schedule.formattedHotelArrival {
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Hotel arrival")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("~\(hotelTime)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Target bedtime
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Target bedtime")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(schedule.formattedBedtime)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    // MARK: - Regular Day Content
    
    private var regularDayContent: some View {
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
    }
    
    // MARK: - Helper
    
    private var strategyIcon: String {
        guard let direction = schedule.travelDirection else {
            return "clock.fill"
        }
        switch direction {
        case .west:
            return "moon.stars.fill"
        case .east:
            return "sunrise.fill"
        case .none:
            return "clock.fill"
        }
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            TimelineCardView(schedule: DailySchedule(
                date: Date(),
                dayLabel: "3 days before",
                bedtime: Date(),
                wakeTime: Date(),
                stage: .preAdjustment,
                travelDirection: .east,
                bodyClockOffsetMinutes: -270
            ))
            
            TimelineCardView(schedule: DailySchedule(
                date: Date(),
                dayLabel: "Travel Day",
                bedtime: Date(),
                wakeTime: Date(),
                stage: .travelDay,
                strategyMessage: "Short morning nap if tired, then stay awake as long as possible",
                hotelArrival: Date(),
                travelDirection: .east,
                bodyClockOffsetMinutes: -180
            ))
            
            TimelineCardView(schedule: DailySchedule(
                date: Date(),
                dayLabel: "Day 2",
                bedtime: Date(),
                wakeTime: Date(),
                stage: .postArrival,
                travelDirection: .east,
                bodyClockOffsetMinutes: -60
            ))
            
            TimelineCardView(schedule: DailySchedule(
                date: Date(),
                dayLabel: "Day 4",
                bedtime: Date(),
                wakeTime: Date(),
                stage: .postArrival,
                travelDirection: .east,
                bodyClockOffsetMinutes: 0
            ))
        }
        .padding()
    }
}
