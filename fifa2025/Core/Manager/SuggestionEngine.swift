import Foundation
import CoreLocation

class SuggestionEngine {
    
    /// Finds blocks of free time between scheduled events.
    static func findFreeTimeSlots(events: [Event], from startDate: Date, to endDate: Date) -> [(start: Date, end: Date)] {
        var freeSlots: [(start: Date, end: Date)] = []
        var lastEventEnd = startDate
        
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        
        for event in sortedEvents {
            if event.startDate > lastEventEnd {
                freeSlots.append((start: lastEventEnd, end: event.startDate))
            }
            lastEventEnd = max(lastEventEnd, event.endDate)
        }
        
        if lastEventEnd < endDate {
            freeSlots.append((start: lastEventEnd, end: endDate))
        }
        
        return freeSlots
    }
    
    /// Generates itinerary suggestions based on free time, location, and available places.
    static func generateSuggestions(
        for freeSlots: [(start: Date, end: Date)],
        from userLocation: CLLocation,
        to locations: [MapLocation]
    ) -> [ItinerarySuggestion] {
        
        var suggestions: [ItinerarySuggestion] = []
        
        for slot in freeSlots {
            let slotDuration = slot.end.timeIntervalSince(slot.start)
            
            // Consider only slots longer than 45 minutes
            guard slotDuration > (45 * 60) else { continue }
            
            // Find the best location for this slot
            let bestLocation = locations
                .map { location -> (location: MapLocation, travelTime: TimeInterval) in
                    let destination = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    // Simple distance-based travel time (approx. 1 min per km)
                    let travelTime = (userLocation.distance(from: destination) / 1000) * 60
                    return (location, travelTime)
                }
                .filter { (location, travelTime) in
                    let totalTimeNeeded = (travelTime * 2) + (30 * 60) // Round trip + 30 mins at location
                    return totalTimeNeeded < slotDuration
                }
                .min { $0.travelTime < $1.travelTime } // Find the closest one
            
            if let best = bestLocation {
                suggestions.append(
                    ItinerarySuggestion(
                        location: best.location,
                        travelTime: best.travelTime,
                        freeTimeSlot: slot,
                        reason: "Fits your \(Int(slotDuration / 60))-minute break"
                    )
                )
            }
        }
        
        return suggestions
    }
}
