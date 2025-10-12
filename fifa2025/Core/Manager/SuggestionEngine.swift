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
            
            // Consider only slots longer than 45 minutes
            guard slotDuration > (45 * 60) else {
                logger.warning("Skipping a slot of \(String(format: "%.2f", slotDurationInMinutes)) minutes because it's less than 45 minutes.")
                continue
            }
            
            logger.info("Evaluating slot of \(String(format: "%.2f", slotDurationInMinutes)) minutes.")
            
            // --- FIX for compiler error ---
            // Step 1: Map locations to include travel time
            let locationsWithTravelTime = locations.map { location -> (location: MapLocation, travelTime: TimeInterval) in
                let destination = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                let distance = userLocation.distance(from: destination)
                let travelTime = (distance / 1000) * 60 // Simple distance-based travel time
                
                let distanceInKm = distance / 1000
                let travelTimeInMinutes = travelTime / 60
                logger.debug("  - Location: \(location.name), Distance: \(String(format: "%.2f", distanceInKm)) km, Travel Time: \(String(format: "%.2f", travelTimeInMinutes)) minutes")
                
                return (location, travelTime)
            }
            
            // Step 2: Filter out locations that don't fit in the time slot
            let suitableLocations = locationsWithTravelTime.filter { (location, travelTime) in
                let totalTimeNeeded = (travelTime * 2) + (30 * 60) // Round trip + 30 mins at location
                let isTimeSufficient = totalTimeNeeded < slotDuration
                
                if !isTimeSufficient {
                    let neededInMinutes = totalTimeNeeded / 60
                    logger.warning("  - Filtering out \(location.name): Needs \(String(format: "%.2f", neededInMinutes)) mins, but slot is only \(String(format: "%.2f", slotDurationInMinutes)) mins.")
                }
                
                return isTimeSufficient
            }
            
            // Step 3: Find the closest location among the suitable ones
            let bestLocation = suitableLocations.min { $0.travelTime < $1.travelTime }
            // --- End of FIX ---
            
            if let best = bestLocation {
                logger.info("Found best location for the slot: \(best.location.name)")
                suggestions.append(
                    ItinerarySuggestion(
                        location: best.location,
                        travelTime: best.travelTime,
                        freeTimeSlot: slot,
                        reason: "Fits your \(Int(slotDuration / 60))-minute break"
                    )
                )
            } else {
                logger.warning("No suitable location found for this time slot.")
            }
        }
        
        logger.info("Generated \(suggestions.count) suggestions.")
        return suggestions
    }
}
