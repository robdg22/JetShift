//
//  TripSetupView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct TripSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var existingTrips: [Trip]
    @Query(sort: \FamilyMember.createdAt) private var familyMembers: [FamilyMember]
    
    // Trip details
    @State private var tripName: String = ""
    
    // Outbound flight
    @State private var outboundDepartureCity: String = "New York"
    @State private var outboundArrivalCity: String = "London"
    @State private var outboundDepartureDate: Date = Date()
    @State private var outboundDepartureTime: Date = Date()
    @State private var outboundArrivalDate: Date = Date()
    @State private var outboundArrivalTime: Date = Date()
    
    // Return flight toggle and details
    @State private var includeReturnFlight: Bool = true
    @State private var returnDepartureDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var returnDepartureTime: Date = Date()
    @State private var returnArrivalDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var returnArrivalTime: Date = Date()
    
    // Strategy
    @State private var selectedStrategy: TripStrategy = .partialAdjustment(percentage: 0.6)
    @State private var showStrategyPicker: Bool = false
    
    // Haptics
    @State private var didSave = false
    @State private var cityChanged = false
    
    private var outboundTimezone: String {
        CityTimezones.timezone(for: outboundDepartureCity) ?? "America/New_York"
    }
    
    private var arrivalTimezone: String {
        CityTimezones.timezone(for: outboundArrivalCity) ?? "Europe/London"
    }
    
    private var timezoneOffset: Int {
        guard let depTZ = TimeZone(identifier: outboundTimezone),
              let arrTZ = TimeZone(identifier: arrivalTimezone) else {
            return 0
        }
        
        let depOffset = depTZ.secondsFromGMT(for: outboundDepartureDate)
        let arrOffset = arrTZ.secondsFromGMT(for: outboundDepartureDate)
        
        return (arrOffset - depOffset) / 3600
    }
    
    private var daysAtDestination: Int {
        guard includeReturnFlight else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: outboundDepartureDate, to: returnDepartureDate).day ?? 0
    }
    
    private var recommendedStrategy: TripStrategy {
        TripRecommendationEngine.recommendStrategy(
            daysAtDestination: daysAtDestination,
            timezoneOffset: timezoneOffset,
            familyMembers: familyMembers
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Trip name
                Section("Trip Name") {
                    TextField("e.g., Summer Europe Trip", text: $tripName)
                }
                
                // Outbound flight
                Section("Outbound Flight") {
                    flightCityPickers(
                        departureCity: $outboundDepartureCity,
                        arrivalCity: $outboundArrivalCity
                    )
                    
                    DatePicker("Departure Date", selection: $outboundDepartureDate, displayedComponents: .date)
                    DatePicker("Departure Time", selection: $outboundDepartureTime, displayedComponents: .hourAndMinute)
                    DatePicker("Arrival Date", selection: $outboundArrivalDate, in: outboundDepartureDate..., displayedComponents: .date)
                    DatePicker("Arrival Time", selection: $outboundArrivalTime, displayedComponents: .hourAndMinute)
                }
                
                // Return flight toggle
                Section {
                    Toggle("Include Return Flight", isOn: $includeReturnFlight.animation(.smooth))
                }
                
                // Return flight details
                if includeReturnFlight {
                    Section("Return Flight") {
                        HStack {
                            Text("From")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(outboundArrivalCity)
                        }
                        
                        HStack {
                            Text("To")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(outboundDepartureCity)
                        }
                        
                        DatePicker("Departure Date", selection: $returnDepartureDate, in: outboundDepartureDate..., displayedComponents: .date)
                        DatePicker("Departure Time", selection: $returnDepartureTime, displayedComponents: .hourAndMinute)
                        DatePicker("Arrival Date", selection: $returnArrivalDate, in: returnDepartureDate..., displayedComponents: .date)
                        DatePicker("Arrival Time", selection: $returnArrivalTime, displayedComponents: .hourAndMinute)
                    }
                    
                    // Trip summary
                    Section("Trip Summary") {
                        LabeledContent("Days at Destination", value: "\(daysAtDestination)")
                        LabeledContent("Timezone Shift", value: formattedTimezoneOffset)
                    }
                }
                
                // Strategy selection
                Section("Adjustment Strategy") {
                    Button {
                        showStrategyPicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedStrategy.icon)
                                .foregroundStyle(selectedStrategy.color)
                            
                            VStack(alignment: .leading) {
                                Text(selectedStrategy.displayName)
                                    .foregroundStyle(.primary)
                                Text(selectedStrategy.shortDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedStrategy == recommendedStrategy {
                                Text("Recommended")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Trip") {
                        saveTrip()
                    }
                    .disabled(tripName.isEmpty)
                }
            }
            .sheet(isPresented: $showStrategyPicker) {
                StrategyPickerView(
                    selectedStrategy: $selectedStrategy,
                    daysAtDestination: daysAtDestination,
                    timezoneOffset: timezoneOffset,
                    familyMembers: familyMembers
                )
            }
            .onAppear {
                // Set recommended strategy on appear
                selectedStrategy = recommendedStrategy
            }
        }
        .sensoryFeedback(.selection, trigger: cityChanged)
        .sensoryFeedback(.success, trigger: didSave)
    }
    
    @ViewBuilder
    private func flightCityPickers(
        departureCity: Binding<String>,
        arrivalCity: Binding<String>
    ) -> some View {
        Picker("From", selection: departureCity) {
            ForEach(CityTimezones.sortedCityNames, id: \.self) { city in
                Text(CityTimezones.cityWithOffset(city))
                    .tag(city)
            }
        }
        .onChange(of: departureCity.wrappedValue) { _, _ in
            cityChanged.toggle()
        }
        
        Picker("To", selection: arrivalCity) {
            ForEach(CityTimezones.sortedCityNames, id: \.self) { city in
                Text(CityTimezones.cityWithOffset(city))
                    .tag(city)
            }
        }
        .onChange(of: arrivalCity.wrappedValue) { _, _ in
            cityChanged.toggle()
        }
    }
    
    private var formattedTimezoneOffset: String {
        let offset = timezoneOffset
        if offset == 0 {
            return "Same timezone"
        }
        
        let direction = offset > 0 ? "eastward" : "westward"
        let hours = abs(offset)
        let hourWord = hours == 1 ? "hour" : "hours"
        
        return "\(hours) \(hourWord) \(direction)"
    }
    
    private func saveTrip() {
        // Create outbound flight
        let outbound = FlightDetails(
            departureCity: outboundDepartureCity,
            departureTimezone: outboundTimezone,
            arrivalCity: outboundArrivalCity,
            arrivalTimezone: arrivalTimezone,
            departureDate: outboundDepartureDate,
            departureTime: outboundDepartureTime,
            arrivalDate: outboundArrivalDate,
            arrivalTime: outboundArrivalTime
        )
        
        // Create return flight if included
        var returnFlight: FlightDetails? = nil
        if includeReturnFlight {
            returnFlight = FlightDetails(
                departureCity: outboundArrivalCity,
                departureTimezone: arrivalTimezone,
                arrivalCity: outboundDepartureCity,
                arrivalTimezone: outboundTimezone,
                departureDate: returnDepartureDate,
                departureTime: returnDepartureTime,
                arrivalDate: returnArrivalDate,
                arrivalTime: returnArrivalTime
            )
        }
        
        // Delete existing trips (single trip for MVP)
        for trip in existingTrips {
            modelContext.delete(trip)
        }
        
        // Create new trip
        let trip = Trip(
            name: tripName,
            homeTimezone: outboundTimezone,
            outboundFlight: outbound,
            returnFlight: returnFlight,
            strategy: selectedStrategy
        )
        
        modelContext.insert(trip)
        didSave.toggle()
        dismiss()
    }
}

#Preview {
    TripSetupView()
        .modelContainer(for: [Trip.self, FamilyMember.self], inMemory: true)
}
