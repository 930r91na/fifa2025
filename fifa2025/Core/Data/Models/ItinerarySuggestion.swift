//
//  ItinerarySuggestion.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation

struct ItinerarySuggestion: Identifiable {
    let id = UUID()
    let location: MapLocation
    let travelTime: TimeInterval
    let freeTimeSlot: (start: Date, end: Date)
    let reason: String 
}
