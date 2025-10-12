import Foundation
import CoreLocation
import OSLog

class SuggestionEngine {
    
    private static let logger = Logger(subsystem: "com.fifa2025.TurismoLocalWC26", category: "SuggestionEngine")
    
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
        
        logger.info("Found \(freeSlots.count) free slots.")
        for (index, slot) in freeSlots.enumerated() {
            let durationInMinutes = slot.end.timeIntervalSince(slot.start) / 60
            logger.debug("  Slot \(index + 1): \(slot.start) to \(slot.end) (Duration: \(String(format: "%.2f", durationInMinutes)) minutes)")
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
        logger.info("Generating suggestions from user location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        
        for slot in freeSlots {
            let slotDuration = slot.end.timeIntervalSince(slot.start)
            let slotDurationInMinutes = slotDuration / 60
            
            guard slotDuration > (45 * 60) else {
                logger.warning("Skipping a slot of \(String(format: "%.2f", slotDurationInMinutes)) minutes because it's less than 45 minutes.")
                continue
            }
            
            logger.info("Evaluating slot of \(String(format: "%.2f", slotDurationInMinutes)) minutes.")
            
            let suitableLocations = locations
                .map { location -> (location: MapLocation, travelTime: TimeInterval) in
                    let destination = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    let distance = userLocation.distance(from: destination)
                    let travelTime = (distance / 1000) * 60
                    return (location, travelTime)
                }
                .filter { (location, travelTime) in
                    let totalTimeNeeded = (travelTime * 2) + (30 * 60) // Round trip + 30 mins at location
                    return totalTimeNeeded < slotDuration
                }

            if suitableLocations.isEmpty {
                logger.warning("No suitable location found for this time slot.")
            } else {
                logger.info("Found \(suitableLocations.count) suitable locations for the slot.")
                for (itemLocation, itemTravelTime) in suitableLocations {
                    let suggestion = ItinerarySuggestion(
                        location: itemLocation,
                        travelTime: itemTravelTime,
                        freeTimeSlot: slot,
                        reason: "Fits your \(Int(slotDurationInMinutes))-minute break"
                    )
                    suggestions.append(suggestion)
                }
            }
        }
        
        suggestions.sort { $0.travelTime < $1.travelTime }
        
        logger.info("Generated \(suggestions.count) total suggestions.")
        return suggestions
    }
}
