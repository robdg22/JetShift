//
//  FlightView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct FlightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var flights: [Flight]
    
    @State private var showingFlightSheet = false
    
    private var currentFlight: Flight? {
        flights.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let flight = currentFlight {
                    flightDetails(flight)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Flight")
            .toolbar {
                if currentFlight != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") {
                            showingFlightSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFlightSheet) {
                if let flight = currentFlight {
                    FlightFormView(mode: .edit(flight))
                } else {
                    FlightFormView(mode: .add)
                }
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Flight Added", systemImage: "airplane")
        } description: {
            Text("Add your flight details to generate jet lag adjustment schedules.")
        } actions: {
            Button {
                showingFlightSheet = true
            } label: {
                Text("Add Flight")
            }
            .buttonStyle(.borderedProminent)
            .sensoryFeedback(.impact(weight: .light), trigger: showingFlightSheet)
        }
    }
    
    private func flightDetails(_ flight: Flight) -> some View {
        List {
            Section {
                flightRouteCard(flight)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            Section("Departure") {
                LabeledContent("City", value: flight.departureCity)
                LabeledContent("Date", value: flight.formattedDepartureDate)
                LabeledContent("Time", value: flight.formattedDepartureTime)
                LabeledContent("Timezone", value: flight.formattedDepartureTimezone)
            }
            
            Section("Arrival") {
                LabeledContent("City", value: flight.arrivalCity)
                LabeledContent("Timezone", value: flight.formattedArrivalTimezone)
            }
            
            Section("Timezone Shift") {
                HStack {
                    Image(systemName: flight.travelDirection == .east ? "arrow.right" : "arrow.left")
                        .foregroundStyle(flight.travelDirection == .east ? .orange : .blue)
                    Text(flight.formattedTimezoneOffset)
                        .font(.headline)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func flightRouteCard(_ flight: Flight) -> some View {
        HStack {
            VStack {
                Text(flight.departureCity)
                    .font(.headline)
                Text("Departure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Image(systemName: "airplane")
                .font(.title2)
                .foregroundStyle(.tint)
            
            VStack {
                Text(flight.arrivalCity)
                    .font(.headline)
                Text("Arrival")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .glassEffect()
    }
}

#Preview {
    FlightView()
        .modelContainer(for: Flight.self, inMemory: true)
}
