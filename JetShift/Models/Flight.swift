//
//  Flight.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation

/// Represents flight details - now a Codable struct embedded in Trip
struct FlightDetails: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var departureCity: String
    var departureTimezone: String
    var arrivalCity: String
    var arrivalTimezone: String
    var departureDate: Date
    var departureTime: Date
    var arrivalDate: Date
    var arrivalTime: Date
    
    init(
        id: UUID = UUID(),
        departureCity: String,
        departureTimezone: String,
        arrivalCity: String,
        arrivalTimezone: String,
        departureDate: Date,
        departureTime: Date,
        arrivalDate: Date,
        arrivalTime: Date
    ) {
        self.id = id
        self.departureCity = departureCity
        self.departureTimezone = departureTimezone
        self.arrivalCity = arrivalCity
        self.arrivalTimezone = arrivalTimezone
        self.departureDate = departureDate
        self.departureTime = departureTime
        self.arrivalDate = arrivalDate
        self.arrivalTime = arrivalTime
    }
    
    /// Calculates the timezone difference in hours (positive = eastward, negative = westward)
    var timezoneOffset: Int {
        guard let depTZ = TimeZone(identifier: departureTimezone),
              let arrTZ = TimeZone(identifier: arrivalTimezone) else {
            return 0
        }
        
        let depOffset = depTZ.secondsFromGMT(for: departureDate)
        let arrOffset = arrTZ.secondsFromGMT(for: departureDate)
        
        return (arrOffset - depOffset) / 3600
    }
    
    /// Returns travel direction
    var travelDirection: TravelDirection {
        if timezoneOffset > 0 {
            return .east
        } else if timezoneOffset < 0 {
            return .west
        } else {
            return .none
        }
    }
    
    /// Formatted timezone offset string
    var formattedTimezoneOffset: String {
        let offset = timezoneOffset
        if offset == 0 {
            return "Same timezone"
        }
        
        let direction = offset > 0 ? "eastward" : "westward"
        let hours = abs(offset)
        let hourWord = hours == 1 ? "hour" : "hours"
        
        return "\(hours) \(hourWord) \(direction)"
    }
    
    /// Formatted departure timezone
    var formattedDepartureTimezone: String {
        guard let tz = TimeZone(identifier: departureTimezone) else {
            return departureTimezone
        }
        let offset = tz.secondsFromGMT(for: departureDate) / 3600
        let sign = offset >= 0 ? "+" : ""
        return "\(departureCity) (GMT\(sign)\(offset))"
    }
    
    /// Formatted arrival timezone
    var formattedArrivalTimezone: String {
        guard let tz = TimeZone(identifier: arrivalTimezone) else {
            return arrivalTimezone
        }
        let offset = tz.secondsFromGMT(for: arrivalDate) / 3600
        let sign = offset >= 0 ? "+" : ""
        return "\(arrivalCity) (GMT\(sign)\(offset))"
    }
    
    /// Formatted departure date
    var formattedDepartureDate: String {
        departureDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Formatted departure time
    var formattedDepartureTime: String {
        departureTime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Formatted arrival time
    var formattedArrivalTime: String {
        arrivalTime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Creates a default outbound flight
    static func defaultOutbound() -> FlightDetails {
        FlightDetails(
            departureCity: "New York",
            departureTimezone: "America/New_York",
            arrivalCity: "London",
            arrivalTimezone: "Europe/London",
            departureDate: Date(),
            departureTime: Date(),
            arrivalDate: Date(),
            arrivalTime: Date()
        )
    }
    
    /// Creates a return flight based on outbound (swapped cities)
    func createReturnFlight(returnDate: Date) -> FlightDetails {
        FlightDetails(
            departureCity: arrivalCity,
            departureTimezone: arrivalTimezone,
            arrivalCity: departureCity,
            arrivalTimezone: departureTimezone,
            departureDate: returnDate,
            departureTime: Date(),
            arrivalDate: returnDate,
            arrivalTime: Date()
        )
    }
}

/// Travel direction for timezone shifts
enum TravelDirection: Codable, Hashable, Sendable {
    case east
    case west
    case none
    
    var description: String {
        switch self {
        case .east: return "Eastward"
        case .west: return "Westward"
        case .none: return "No change"
        }
    }
    
    /// Opposite direction (for return flights)
    var opposite: TravelDirection {
        switch self {
        case .east: return .west
        case .west: return .east
        case .none: return .none
        }
    }
}
