//
//  Trip.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation
import SwiftData

/// Represents a complete trip with outbound and optional return flights
@Model
final class Trip {
    var id: UUID = UUID()
    var name: String = ""
    var homeTimezone: String = ""
    
    // Flights stored as Codable structs
    var outboundFlightData: Data? = nil
    var returnFlightData: Data? = nil
    
    // Strategy stored as Codable
    var strategyData: Data? = nil
    
    var createdAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        name: String,
        homeTimezone: String,
        outboundFlight: FlightDetails,
        returnFlight: FlightDetails? = nil,
        strategy: TripStrategy = .fullAdjustment,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.homeTimezone = homeTimezone
        self.createdAt = createdAt
        
        // Encode flights and strategy
        self.outboundFlightData = try? JSONEncoder().encode(outboundFlight)
        self.returnFlightData = returnFlight.flatMap { try? JSONEncoder().encode($0) }
        self.strategyData = try? JSONEncoder().encode(strategy)
    }
    
    // MARK: - Computed Properties
    
    /// Decoded outbound flight
    var outboundFlight: FlightDetails? {
        get {
            guard let data = outboundFlightData else { return nil }
            return try? JSONDecoder().decode(FlightDetails.self, from: data)
        }
        set {
            outboundFlightData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
    
    /// Decoded return flight
    var returnFlight: FlightDetails? {
        get {
            guard let data = returnFlightData else { return nil }
            return try? JSONDecoder().decode(FlightDetails.self, from: data)
        }
        set {
            returnFlightData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
    
    /// Decoded strategy
    var strategy: TripStrategy {
        get {
            guard let data = strategyData else { return .fullAdjustment }
            return (try? JSONDecoder().decode(TripStrategy.self, from: data)) ?? .fullAdjustment
        }
        set {
            strategyData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Whether this trip has a return flight
    var hasReturnFlight: Bool {
        returnFlight != nil
    }
    
    /// Number of days at destination
    var daysAtDestination: Int {
        guard let outbound = outboundFlight,
              let returnFlight = returnFlight else {
            return 0
        }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: outbound.departureDate, to: returnFlight.departureDate).day ?? 0
        return max(0, days)
    }
    
    /// Timezone difference for the trip
    var timezoneOffset: Int {
        outboundFlight?.timezoneOffset ?? 0
    }
    
    /// Travel direction
    var travelDirection: TravelDirection {
        outboundFlight?.travelDirection ?? .none
    }
    
    /// Destination city
    var destinationCity: String {
        outboundFlight?.arrivalCity ?? ""
    }
    
    /// Home city
    var homeCity: String {
        outboundFlight?.departureCity ?? ""
    }
    
    /// Formatted trip summary
    var tripSummary: String {
        guard let outbound = outboundFlight else { return "" }
        if hasReturnFlight {
            return "\(outbound.departureCity) → \(outbound.arrivalCity) → \(outbound.departureCity)"
        }
        return "\(outbound.departureCity) → \(outbound.arrivalCity)"
    }
    
    /// Formatted date range
    var dateRange: String {
        guard let outbound = outboundFlight else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startDate = formatter.string(from: outbound.departureDate)
        
        if let returnFlight = returnFlight {
            let endDate = formatter.string(from: returnFlight.departureDate)
            return "\(startDate) - \(endDate)"
        }
        
        return startDate
    }
}
