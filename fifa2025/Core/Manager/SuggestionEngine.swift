import Foundation
import CoreLocation
import OSLog
import CoreML

class SuggestionEngine {
    
    private static let logger = Logger(subsystem: "com.fifa2025.TurismoLocalWC26", category: "SuggestionEngine")
    
    /// Finds blocks of free time between scheduled events. (This function remains unchanged)
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
        return freeSlots
    }
    
    /// **MODIFIED**: Generates itinerary suggestions using a Core ML model first, then filters by logistics.
    static func generateSuggestions(
        for freeSlots: [(start: Date, end: Date)],
        from userLocation: CLLocation,
        for user: User,
        allLocations: [MapLocation]
    ) -> [ItinerarySuggestion] {
        
        logger.info("--- Starting New Suggestion Generation for user: \(user.name) ---")

        // Get a personalized, ranked list of locations from the Core ML model.
        let recommendedLocations = getMLRecommendations(for: user, from: allLocations)
        
        // If the model provides recommendations, use them. Otherwise, fall back to all locations.
        let locationsToConsider = recommendedLocations.isEmpty ? allLocations : recommendedLocations
        
        var suggestions: [ItinerarySuggestion] = []
        logger.info("Considering \(locationsToConsider.count) locations for scheduling.")

        for slot in freeSlots {
            let slotDuration = slot.end.timeIntervalSince(slot.start)
            
            guard slotDuration > (45 * 60) else { continue }
            
            let suitableLocations = locationsToConsider
                .map { location -> (location: MapLocation, travelTime: TimeInterval) in
                    let destination = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    let distance = userLocation.distance(from: destination)
                    let travelTime = (distance / 1000) * 5 * 60
                    return (location, travelTime)
                }
                .filter { (location, travelTime) in
                    let totalTimeNeeded = (travelTime * 2) + (30 * 60)
                    return totalTimeNeeded < slotDuration
                }

            if !suitableLocations.isEmpty {
                for (itemLocation, itemTravelTime) in suitableLocations {
                    let suggestion = ItinerarySuggestion(
                        location: itemLocation,
                        travelTime: itemTravelTime,
                        freeTimeSlot: slot,
                        reason: "A great fit for your schedule and tastes!"
                    )
                    suggestions.append(suggestion)
                }
            }
        }
        
        let finalSuggestions = Array(suggestions.prefix(10))
        logger.info("Generated \(finalSuggestions.count) final suggestions.")
        return finalSuggestions
    }

    /// **CORRECTED**: Private helper function to interact with the Core ML model.
    private static func getMLRecommendations(for user: User, from allLocations: [MapLocation]) -> [MapLocation] {
        do {
            let model = try TurismoLocalRecommender(configuration: MLModelConfiguration())
            
            // --- DATA PREPARATION ---
            
            // 1. Create the user's interaction history: [String: Double]
            // This is how the model learns the user's taste from their past visits.
            let interactionHistory = Dictionary(uniqueKeysWithValues: user.visits.map { ($0.location.name, Double($0.rating)) })
            
            logger.debug("User Interaction History for Model: \(interactionHistory)")
            
            // 2. Create the list of candidate items to be ranked.
            // These are items the user has NOT visited yet.
            let visitedLocationNames = Set(user.visits.map { $0.location.name })
            let candidateItems = allLocations.filter { !visitedLocationNames.contains($0.name) }.map { $0.name }
            
            guard !candidateItems.isEmpty else {
                logger.info("User has visited all available locations. No new recommendations.")
                return []
            }
            logger.debug("\(candidateItems.count) candidate items to be ranked.")

            // --- MODEL PREDICTION ---
            
            // 3. **FIXED**: Call the model with the correct inputs.
            // 'items' gets the user's history, 'restrict' gets the candidate items.
            let input = TurismoLocalRecommenderInput(items: interactionHistory, k: 20)
            
            // 4. Get the prediction from the model.
            let predictions = try model.prediction(input: input)
            
            // --- PROCESSING RESULTS ---
            
            let recommendedItemNames = predictions.recommendations
            logger.info("Core ML returned \(recommendedItemNames.count) ranked items: \(recommendedItemNames.prefix(5))...")
            
            // Map the sorted names back to the full MapLocation objects.
            let locationNameMap = allLocations.reduce(into: [String: MapLocation]()) { $0[$1.name] = $1 }
            let sortedLocations = recommendedItemNames.compactMap { locationNameMap[$0] }
            
            return sortedLocations
            
        } catch {
            logger.error("Error predicting with Core ML model: \(error)")
            // Fall back if the model fails.
            return []
        }
    }
}
