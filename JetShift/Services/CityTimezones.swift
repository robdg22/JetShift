//
//  CityTimezones.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import Foundation

/// Service for looking up city timezones
struct CityTimezones {
    /// Dictionary of city names to timezone identifiers
    static let cities: [String: String] = [
        "New York": "America/New_York",
        "Los Angeles": "America/Los_Angeles",
        "London": "Europe/London",
        "Paris": "Europe/Paris",
        "Tokyo": "Asia/Tokyo",
        "Sydney": "Australia/Sydney",
        "Dubai": "Asia/Dubai",
        "Singapore": "Asia/Singapore",
        "Hong Kong": "Asia/Hong_Kong",
        "Mumbai": "Asia/Kolkata",
        "Toronto": "America/Toronto",
        "Chicago": "America/Chicago",
        "San Francisco": "America/Los_Angeles",
        "Boston": "America/New_York",
        "Miami": "America/New_York",
        "Berlin": "Europe/Berlin",
        "Rome": "Europe/Rome",
        "Madrid": "Europe/Madrid",
        "Amsterdam": "Europe/Amsterdam",
        "Bangkok": "Asia/Bangkok",
        "Beijing": "Asia/Shanghai",
        "Seoul": "Asia/Seoul",
        "Melbourne": "Australia/Melbourne"
    ]
    
    /// Sorted list of city names for UI display
    static var sortedCityNames: [String] {
        cities.keys.sorted()
    }
    
    /// Get timezone identifier for a city
    static func timezone(for city: String) -> String? {
        cities[city]
    }
    
    /// Get formatted timezone offset string for a city
    static func formattedOffset(for city: String, at date: Date = Date()) -> String {
        guard let identifier = cities[city],
              let tz = TimeZone(identifier: identifier) else {
            return ""
        }
        
        let offset = tz.secondsFromGMT(for: date) / 3600
        let sign = offset >= 0 ? "+" : ""
        return "GMT\(sign)\(offset)"
    }
    
    /// Get city with timezone description
    static func cityWithOffset(_ city: String, at date: Date = Date()) -> String {
        let offset = formattedOffset(for: city, at: date)
        if offset.isEmpty {
            return city
        }
        return "\(city) (\(offset))"
    }
}
