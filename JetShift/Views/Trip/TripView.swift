//
//  TripView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct TripView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]
    
    @State private var showingTripSheet = false
    @State private var showingStrategyExplanation = false
    
    private var currentTrip: Trip? {
        trips.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let trip = currentTrip {
                    tripDetails(trip)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Trip")
            .toolbar {
                if currentTrip != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") {
                            showingTripSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTripSheet) {
                TripSetupView()
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Trip Added", systemImage: "airplane")
        } description: {
            Text("Add your trip details to generate jet lag adjustment schedules for your family.")
        } actions: {
            Button {
                showingTripSheet = true
            } label: {
                Text("Add Trip")
            }
            .buttonStyle(.borderedProminent)
            .sensoryFeedback(.impact(weight: .light), trigger: showingTripSheet)
        }
    }
    
    private func tripDetails(_ trip: Trip) -> some View {
        List {
            // Trip route card
            Section {
                tripRouteCard(trip)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // Outbound flight
            if let outbound = trip.outboundFlight {
                Section("Outbound Flight") {
                    LabeledContent("From", value: outbound.formattedDepartureTimezone)
                    LabeledContent("To", value: outbound.formattedArrivalTimezone)
                    LabeledContent("Departure", value: outbound.formattedDepartureDate)
                    LabeledContent("Time", value: outbound.formattedDepartureTime)
                    
                    // Timezone shift
                    HStack {
                        Image(systemName: outbound.travelDirection == .east ? "arrow.right" : "arrow.left")
                            .foregroundStyle(outbound.travelDirection == .east ? .orange : .blue)
                        Text(outbound.formattedTimezoneOffset)
                            .font(.subheadline)
                    }
                }
            }
            
            // Return flight
            if let returnFlight = trip.returnFlight {
                Section("Return Flight") {
                    LabeledContent("From", value: returnFlight.formattedDepartureTimezone)
                    LabeledContent("To", value: returnFlight.formattedArrivalTimezone)
                    LabeledContent("Departure", value: returnFlight.formattedDepartureDate)
                    LabeledContent("Time", value: returnFlight.formattedDepartureTime)
                }
                
                Section("Trip Duration") {
                    LabeledContent("Days at Destination", value: "\(trip.daysAtDestination)")
                }
            }
            
            // Strategy
            Section("Adjustment Strategy") {
                Button {
                    showingStrategyExplanation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: trip.strategy.icon)
                            .font(.title2)
                            .foregroundStyle(trip.strategy.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.strategy.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(trip.strategy.shortDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Delete trip
            Section {
                Button(role: .destructive) {
                    deleteTrip(trip)
                } label: {
                    Label("Delete Trip", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingStrategyExplanation) {
            strategyExplanationSheet(trip)
        }
    }
    
    private func tripRouteCard(_ trip: Trip) -> some View {
        VStack(spacing: 16) {
            // Trip name
            Text(trip.name)
                .font(.title3)
                .fontWeight(.semibold)
            
            // Route visualization
            HStack {
                VStack {
                    Text(trip.homeCity)
                        .font(.headline)
                    Text("Home")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: "airplane.departure")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    
                    if trip.hasReturnFlight {
                        Image(systemName: "airplane.arrival")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }
                }
                
                VStack {
                    Text(trip.destinationCity)
                        .font(.headline)
                    Text("Destination")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Strategy badge
            HStack {
                Image(systemName: trip.strategy.icon)
                    .font(.caption)
                Text(trip.strategy.displayName)
                    .font(.caption)
            }
            .foregroundStyle(trip.strategy.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(trip.strategy.color.opacity(0.15), in: Capsule())
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func strategyExplanationSheet(_ trip: Trip) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: trip.strategy.icon)
                        .font(.largeTitle)
                        .foregroundStyle(trip.strategy.color)
                    
                    VStack(alignment: .leading) {
                        Text(trip.strategy.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(trip.strategy.shortDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Detailed description
                Text(trip.strategy.detailedDescription)
                    .font(.body)
                
                // Pros
                VStack(alignment: .leading, spacing: 8) {
                    Text("Benefits")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    ForEach(trip.strategy.pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(pro)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Cons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Considerations")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    
                    ForEach(trip.strategy.cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(con)
                                .font(.subheadline)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Strategy Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingStrategyExplanation = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
    }
}

#Preview {
    TripView()
        .modelContainer(for: Trip.self, inMemory: true)
}
