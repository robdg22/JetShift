//
//  FlightFormView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct FlightFormView: View {
    enum Mode {
        case add
        case edit(Flight)
        
        var title: String {
            switch self {
            case .add: return "Add Flight"
            case .edit: return "Edit Flight"
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .add: return "Add Flight"
            case .edit: return "Save Changes"
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingFlights: [Flight]
    
    let mode: Mode
    
    @State private var departureCity: String = "New York"
    @State private var arrivalCity: String = "London"
    @State private var departureDate: Date = Date()
    @State private var departureTime: Date = Date()
    @State private var arrivalDate: Date = Date()
    @State private var arrivalTime: Date = Date()
    
    @State private var didSave = false
    @State private var cityChanged = false
    
    private var departureTimezone: String {
        CityTimezones.timezone(for: departureCity) ?? "America/New_York"
    }
    
    private var arrivalTimezone: String {
        CityTimezones.timezone(for: arrivalCity) ?? "Europe/London"
    }
    
    private var timezoneOffset: Int {
        guard let depTZ = TimeZone(identifier: departureTimezone),
              let arrTZ = TimeZone(identifier: arrivalTimezone) else {
            return 0
        }
        
        let depOffset = depTZ.secondsFromGMT(for: departureDate)
        let arrOffset = arrTZ.secondsFromGMT(for: departureDate)
        
        return (arrOffset - depOffset) / 3600
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
    
    init(mode: Mode) {
        self.mode = mode
        
        if case .edit(let flight) = mode {
            _departureCity = State(initialValue: flight.departureCity)
            _arrivalCity = State(initialValue: flight.arrivalCity)
            _departureDate = State(initialValue: flight.departureDate)
            _departureTime = State(initialValue: flight.departureTime)
            _arrivalDate = State(initialValue: flight.arrivalDate)
            _arrivalTime = State(initialValue: flight.arrivalTime)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Departure") {
                    Picker("City", selection: $departureCity) {
                        ForEach(CityTimezones.sortedCityNames, id: \.self) { city in
                            Text(CityTimezones.cityWithOffset(city, at: departureDate))
                                .tag(city)
                        }
                    }
                    .onChange(of: departureCity) { _, _ in
                        cityChanged.toggle()
                    }
                    
                    DatePicker(
                        "Date",
                        selection: $departureDate,
                        displayedComponents: .date
                    )
                    
                    DatePicker(
                        "Time",
                        selection: $departureTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section("Arrival") {
                    Picker("City", selection: $arrivalCity) {
                        ForEach(CityTimezones.sortedCityNames, id: \.self) { city in
                            Text(CityTimezones.cityWithOffset(city, at: arrivalDate))
                                .tag(city)
                        }
                    }
                    .onChange(of: arrivalCity) { _, _ in
                        cityChanged.toggle()
                    }
                    
                    DatePicker(
                        "Date",
                        selection: $arrivalDate,
                        in: departureDate...,
                        displayedComponents: .date
                    )
                    
                    DatePicker(
                        "Time",
                        selection: $arrivalTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section("Timezone Shift") {
                    HStack {
                        Image(systemName: timezoneOffset >= 0 ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                            .foregroundStyle(timezoneOffset > 0 ? .orange : timezoneOffset < 0 ? .blue : .secondary)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(formattedTimezoneOffset)
                                .font(.headline)
                            
                            if timezoneOffset != 0 {
                                Text(timezoneOffset > 0 ? "Bedtimes will shift earlier" : "Bedtimes will shift later")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .animation(.smooth, value: timezoneOffset)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.buttonTitle) {
                        save()
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: cityChanged)
        .sensoryFeedback(.success, trigger: didSave)
    }
    
    private func save() {
        switch mode {
        case .add:
            // Remove any existing flights first (single flight for MVP)
            for flight in existingFlights {
                modelContext.delete(flight)
            }
            
            let flight = Flight(
                departureCity: departureCity,
                departureTimezone: departureTimezone,
                arrivalCity: arrivalCity,
                arrivalTimezone: arrivalTimezone,
                departureDate: departureDate,
                departureTime: departureTime,
                arrivalDate: arrivalDate,
                arrivalTime: arrivalTime
            )
            modelContext.insert(flight)
            
        case .edit(let flight):
            flight.departureCity = departureCity
            flight.departureTimezone = departureTimezone
            flight.arrivalCity = arrivalCity
            flight.arrivalTimezone = arrivalTimezone
            flight.departureDate = departureDate
            flight.departureTime = departureTime
            flight.arrivalDate = arrivalDate
            flight.arrivalTime = arrivalTime
        }
        
        didSave.toggle()
        dismiss()
    }
}

#Preview("Add") {
    FlightFormView(mode: .add)
        .modelContainer(for: Flight.self, inMemory: true)
}
