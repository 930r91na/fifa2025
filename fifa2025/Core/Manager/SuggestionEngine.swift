
import Foundation
import CoreLocation
import OSLog
import CoreML

// MARK: - Place Data Model
struct PlaceData: Codable {
    let place_id: String
    let name: String
    let primary_type: String
    let rating: String
    let lat: String
    let lng: String
    let formatted_address: String?
    let phone_national: String?
    let website: String?
    let photo_uri: String?
    let business_category: String?
    let business_size: String?
    let near_stadium: String?
    let denue_id: String?
    let priority: String?
    let recommendation_weight: String?
}

// MARK: - Smart Itinerary Suggestion
struct SmartItinerarySuggestion: Identifiable {
    let id = UUID()
    let places: [ItineraryStop]
    let totalDuration: TimeInterval
    let totalDistance: Double
    let mealStops: [MealType: ItineraryStop]
    let itineraryType: ItineraryType
}

enum ItineraryType: CustomStringConvertible {
    case quickBite
    case express
    case short
    case standard
    case extended

    var description: String {
        switch self {
        case .quickBite: return "quickBite"
        case .express: return "express"
        case .short: return "short"
        case .standard: return "standard"
        case .extended: return "extended"
        }
    }
}

struct ItineraryStop {
    let place: MapLocation
    let placeData: PlaceData
    let arrivalTime: Date
    let departureTime: Date
    let travelTimeFromPrevious: TimeInterval
    let suggestedDuration: TimeInterval
    let mealType: MealType?
}

enum MealType: String {
    case breakfast = "Desayuno"
    case lunch = "Comida"
    case dinner = "Cena"
    case snack = "Snack"
}

class SuggestionEngine {

    private static let logger = Logger(subsystem: "com.fifa2025.TurismoLocalWC26", category: "SuggestionEngine")

    private static var placesDataCache: [String: PlaceData]?
    private static var denueIDCache: [String: PlaceData]?

    // MARK: - Category Filtering
    private static let excludedKeywords: Set<String> = [
        "reparación de suspensiones", "alineación", "balanceo",
        "suspensiones de automóviles", "suspensiones de camiones",
        "cerrajería", "cerrajerías", "lavandería", "lavanderías",
        "tintorería", "tintorerías", "sanitarios públicos", "bolería", "bolerías",
        "consultorio dental", "consultorios dentales", "orfanato", "orfanatos",
        "residencias de asistencia social",
        "impresión de formas", "elaboración de chocolate", "elaboración de tortillas",
        "purificación", "embotellado", "conservación de guisos",
        "otras industrias manufactureras", "manufactura",
        "captación, tratamiento y suministro de agua",
        "tratamiento y suministro de agua",
        "reparación y mantenimiento", "reparación de",
        "lotería", "billetes de lotería", "pronósticos deportivos",
        "bufete", "bufetes jurídicos",
        "juegos electrónicos", "casas de juegos electrónicos",
        "gimnasio del sector privado", "centros de acondicionamiento físico del sector privado",
        "diseño de modas", "agencias de viajes"
    ]

    private static let excludedWebsiteDomains: Set<String> = [
        "starbucks.com", "starbucks.com.mx",
        "mcdonalds.com", "mcdonalds.com.mx",
        "subway.com", "subway.com.mx",
        "kfc.com", "kfc.com.mx",
        "burgerking.com", "burgerking.com.mx",
        "dominos.com", "dominos.com.mx",
        "pizzahut.com", "pizzahut.com.mx",
        "wendys.com", "wendys.com.mx",
        "dunkindonuts.com", "dunkin.com",
        "oxxo.com", "7-eleven.com", "seveneleven.com",
        "extraconvenience.com", "circlek.com",
        "walmart.com", "walmart.com.mx",
        "soriana.com", "chedraui.com",
        "sams.com", "costco.com"
    ]

    private static let excludedChainNames: Set<String> = [
        "starbucks", "mcdonald's", "mcdonalds", "subway", "kfc", "palacio de hierro","liverpool",
        "burger king", "domino's", "dominos", "pizza hut",
        "wendy's", "wendys", "dunkin donuts", "dunkin'",
        "oxxo", "seven eleven", "7-eleven", "7 eleven",
        "extra", "circle k",
        "walmart", "soriana", "chedraui", "bodega aurrera",
        "sam's club", "sams", "costco",
        "farmacia guadalajara", "farmacias del ahorro",
        "farmacia san pablo", "benavides"
    ]

    private static func isAllowedCategory(_ category: String?, website: String? = nil, name: String? = nil) -> Bool {
        if let web = website?.lowercased() {
            for excludedDomain in excludedWebsiteDomains {
                if web.contains(excludedDomain) {
                    logger.debug("Excluding chain by website: \(name ?? "unknown")")
                    return false
                }
            }
        }

        if let placeName = name?.lowercased() {
            for excludedChain in excludedChainNames {
                if placeName.contains(excludedChain) {
                    logger.debug("Excluding chain by name: \(placeName)")
                    return false
                }
            }
        }

        guard let cat = category?.lowercased() else { return true }

        if isFood(category) {
            if cat.contains("elaboración de tortillas") ||
               cat.contains("conservación de guisos") ||
               cat.contains("molienda de nixtamal") {
                return false
            }
            return true
        }

        for excluded in excludedKeywords {
            if cat.contains(excluded.lowercased()) {
                logger.debug("Excluding by category: \(category ?? "unknown")")
                return false
            }
        }

        return true
    }

    // MARK: - Load Dataset
    static func loadPlacesDataset() -> [String: PlaceData] {
        if let cache = placesDataCache {
            return cache
        }

        guard let url = Bundle.main.url(forResource: "dataset_FINAL2026", withExtension: "csv") else {
            logger.error("Dataset CSV not found")
            return [:]
        }

        do {
            let csvData = try String(contentsOf: url, encoding: .utf8)
            let rows = csvData.components(separatedBy: .newlines)

            guard rows.count > 1 else {
                logger.error("CSV has only \(rows.count) rows")
                return [:]
            }

            let firstRow = rows[0]
            let separator = firstRow.contains("\t") ? "\t" : ","

            var placesDict: [String: PlaceData] = [:]
            var denueDict: [String: PlaceData] = [:]

            for i in 1..<rows.count {
                let row = rows[i]
                guard !row.isEmpty else { continue }

                let columns = parseCSVRow(row, separator: separator)
                guard columns.count >= 20 else { continue }

                let placeID = columns[safe: 0] ?? ""
                guard !placeID.isEmpty else { continue }

                let denueID = columns[safe: 20] ?? ""

                let placeData = PlaceData(
                    place_id: placeID,
                    name: columns[safe: 3] ?? "Unknown",
                    primary_type: columns[safe: 2] ?? "",
                    rating: columns[safe: 5] ?? "N/A",
                    lat: columns[safe: 10] ?? "0",
                    lng: columns[safe: 11] ?? "0",
                    formatted_address: columns[safe: 18],
                    phone_national: columns[safe: 15],
                    website: columns[safe: 14],
                    photo_uri: columns[safe: 12],
                    business_category: columns[safe: 19],
                    business_size: columns[safe: 21],
                    near_stadium: columns[safe: 24],
                    denue_id: denueID.isEmpty ? nil : denueID,
                    priority: columns[safe: 22],
                    recommendation_weight: columns[safe: 23]
                )

                guard isAllowedCategory(placeData.business_category,
                                       website: placeData.website,
                                       name: placeData.name) else {
                    continue
                }

                placesDict[placeID] = placeData

                if !denueID.isEmpty {
                    denueDict[denueID] = placeData
                    if denueID.hasPrefix("INEGI_") {
                        let bareID = String(denueID.dropFirst(6))
                        denueDict[bareID] = placeData
                    } else {
                        denueDict["INEGI_\(denueID)"] = placeData
                    }
                }
            }

            placesDataCache = placesDict
            denueIDCache = denueDict
            logger.info("Loaded \(placesDict.count) places, DENUE index: \(denueDict.count)")
            return placesDict

        } catch {
            logger.error("Error loading dataset: \(error)")
            return [:]
        }
    }

    private static func cleanField(_ field: String) -> String {
        var cleaned = field
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        cleaned = cleaned.replacingOccurrences(of: "\"\"", with: "\"")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseCSVRow(_ row: String, separator: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        let sepChar = separator.first!

        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == sepChar && !insideQuotes {
                result.append(cleanField(currentField))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(cleanField(currentField))
        return result
    }

    static func loadAllLocations() -> [MapLocation] {
        let placesData = loadPlacesDataset()
        guard !placesData.isEmpty else { return [] }

        let locations = placesData.values.compactMap { placeData -> MapLocation? in
            guard let lat = Double(placeData.lat),
                  let lng = Double(placeData.lng),
                  lat != 0.0 || lng != 0.0 else {
                return nil
            }

            guard isAllowedCategory(placeData.business_category,
                                   website: placeData.website,
                                   name: placeData.name) else {
                return nil
            }

            return MapLocation(
                id: placeData.place_id,
                denueID: placeData.denue_id ?? placeData.place_id,
                name: placeData.name,
                type: mapTypeFromCategory(placeData.business_category),
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                description: placeData.primary_type,
                imageName: "placeholder_location",
                promotesWomenInSports: false,
                address: placeData.formatted_address,
                phoneNumber: placeData.phone_national,
                website: placeData.website
            )
        }

        logger.info("Converted \(locations.count) MapLocations")
        return locations
    }

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

        logger.info("Found \(freeSlots.count) free slots")
        return freeSlots
    }

    // MARK: - Generate Smart Suggestions
    static func generateSmartSuggestions(
        for freeSlots: [(start: Date, end: Date)],
        from userLocation: CLLocation,
        for user: User,
        allLocations: [MapLocation]
    ) -> [SmartItinerarySuggestion] {

        logger.info("Starting Smart Suggestion Generation for \(user.name)")
        logger.info("User location: (\(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude))")
        if let archetype = user.archetype {
            logger.info("User archetype: \(archetype.displayName)")
        }

        let placesData = loadPlacesDataset()
        guard !placesData.isEmpty else {
            logger.error("No places data available")
            return []
        }

        let recommendedDenueIDs = getMLRecommendations(for: user, from: allLocations, userLocation: userLocation)

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        let startDate: Date
        if currentHour >= 22 {
            startDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
                .addingTimeInterval(8 * 3600)
        } else {
            startDate = now
        }

        let endDate = calendar.startOfDay(for: startDate).addingTimeInterval(22 * 3600)

        logger.info("Full day itinerary: \(startDate) to \(endDate)")

        if let fullDayItinerary = buildFullDayItinerary(
            startTime: startDate,
            endTime: endDate,
            userLocation: userLocation,
            recommendedDenueIDs: recommendedDenueIDs,
            userInterests: user.interests,
            userArchetype: user.archetype,
            existingEvents: []
        ) {
            logger.info("Created full day itinerary with \(fullDayItinerary.places.count) stops")
            return [fullDayItinerary]
        }

        logger.warning("Could not create full day itinerary, falling back to slot-based")

        var suggestions: [SmartItinerarySuggestion] = []
        for (index, slot) in freeSlots.enumerated() {
            let slotDuration = slot.end.timeIntervalSince(slot.start)
            let durationMinutes = Int(slotDuration / 60)

            logger.info("Slot \(index + 1): \(durationMinutes) mins")

            guard slotDuration >= (15 * 60) else { continue }

            if let itinerary = buildSmartItinerary(
                startTime: slot.start,
                endTime: slot.end,
                userLocation: userLocation,
                recommendedDenueIDs: recommendedDenueIDs,
                userInterests: user.interests,
                userArchetype: user.archetype
            ) {
                suggestions.append(itinerary)
            }
        }

        logger.info("Generated \(suggestions.count) slot-based itineraries")
        return suggestions
    }

    // MARK: - 🆕 Sistema de Scoring por Arquetipo
    private static func getArchetypeBonus(
        category: String?,
        archetype: UserArchetype?
    ) -> Double {
        guard let cat = category?.lowercased(),
              let arch = archetype else {
            return 0.0
        }
        
        switch arch {
            
        // 🍽️ Gourmet Foodie - SOLO restaurantes elegantes
        case .gourmetFoodie:
            if cat.contains("restaurante") &&
               !cat.contains("taquería") &&
               !cat.contains("antojitos") &&
               !cat.contains("comida rápida") {
                return 150.0
            }
            if cat.contains("cafetería") && !cat.contains("café internet") {
                return 100.0
            }
            if cat.contains("café") && !cat.contains("internet") {
                return 90.0
            }
            if cat.contains("panadería") || cat.contains("pastelería") {
                return 70.0
            }
            if cat.contains("taquería") || cat.contains("antojitos") {
                return 5.0  // Penalización
            }
            return 10.0
            
        // 🌮 Street Food Fan - SOLO comida callejera
        case .streetFoodFan:
            if cat.contains("taquería") || cat.contains("antojitos") {
                return 150.0
            }
            if cat.contains("puesto") || cat.contains("stand") {
                return 140.0
            }
            if cat.contains("mercado") || cat.contains("market") {
                return 120.0
            }
            if cat.contains("comida") && !cat.contains("restaurante") {
                return 110.0
            }
            if cat.contains("restaurante") && !cat.contains("taquería") {
                return 10.0  // Penalización para restaurantes elegantes
            }
            return 5.0
            
        // 🎨 Art & History Buff - SOLO cultura
        case .artHistoryBuff:
            if cat.contains("museo") || cat.contains("museum") {
                return 200.0  // Máxima prioridad
            }
            if cat.contains("galería") || cat.contains("gallery") {
                return 180.0
            }
            if cat.contains("monumento") || cat.contains("monument") {
                return 170.0
            }
            if cat.contains("iglesia") || cat.contains("church") ||
               cat.contains("catedral") || cat.contains("cathedral") {
                return 160.0
            }
            if cat.contains("histórico") || cat.contains("historical") ||
               cat.contains("heritage") || cat.contains("patrimonio") {
                return 150.0
            }
            if cat.contains("biblioteca") || cat.contains("library") {
                return 140.0
            }
            if cat.contains("cultural") || cat.contains("culture") {
                return 130.0
            }
            if cat.contains("restaurante") || cat.contains("bar") {
                return 5.0  // Muy baja prioridad
            }
            return 0.0
            
        // 🎉 Nightlife Seeker - SOLO vida nocturna
        case .nightlifeSeeker:
            if cat.contains("bar") && !cat.contains("barbería") && !cat.contains("barbacoa") {
                return 180.0
            }
            if cat.contains("club") || cat.contains("discoteca") {
                return 170.0
            }
            if cat.contains("cantina") || cat.contains("cervecería") {
                return 160.0
            }
            if cat.contains("night") || cat.contains("nocturno") {
                return 150.0
            }
            if cat.contains("karaoke") || cat.contains("billar") {
                return 140.0
            }
            if cat.contains("restaurante") && cat.contains("bar") {
                return 120.0
            }
            if cat.contains("museo") || cat.contains("iglesia") {
                return 0.0  // Sin interés
            }
            return 5.0
            
        // ⚽ Sports Fanatic - SOLO deportes
        case .sportsFanatic:
            if cat.contains("estadio") || cat.contains("stadium") {
                return 500.0  // ⭐ MÁXIMA PRIORIDAD - DUPLICADO
            }
            if cat.contains("arena") || cat.contains("campo deportivo") {
                return 400.0
            }
            if cat.contains("sports bar") ||
               (cat.contains("bar") && (cat.contains("deport") || cat.contains("futbol") || cat.contains("sports"))) {
                return 200.0
            }
            if cat.contains("bowling") || cat.contains("boliche") {
                return 180.0
            }
            if cat.contains("gimnasio") && cat.contains("público") {
                return 150.0
            }
            // ⚠️ Bares normales (sin deportes) - MUY BAJO
            if cat.contains("bar") && !cat.contains("barbería") &&
               !cat.contains("deport") && !cat.contains("sports") && !cat.contains("futbol") {
                return 40.0  // Reducido drásticamente
            }
            if cat.contains("cantina") {
                return 35.0
            }
            if cat.contains("museo") || cat.contains("galería") {
                return 5.0
            }
            return 10.0
            
        // 🎒 Budget Backpacker - SOLO económico
        case .budgetBackpacker:
            if cat.contains("taquería") || cat.contains("antojitos") {
                return 140.0
            }
            if cat.contains("mercado") || cat.contains("market") {
                return 150.0
            }
            if cat.contains("puesto") || cat.contains("stand") {
                return 130.0
            }
            if cat.contains("parque") || cat.contains("park") {
                return 120.0  // Gratis!
            }
            if cat.contains("museo") && cat.contains("gratis") {
                return 110.0
            }
            if cat.contains("restaurante") && !cat.contains("taquería") {
                return 5.0  // Muy bajo
            }
            if cat.contains("luxury") || cat.contains("lujo") || cat.contains("boutique") {
                return 0.0  // Sin interés
            }
            return 20.0
            
        // 💎 Luxury Traveler - SOLO premium
        case .luxuryTraveler:
            if cat.contains("luxury") || cat.contains("lujo") {
                return 200.0
            }
            if cat.contains("restaurante") &&
               !cat.contains("taquería") &&
               !cat.contains("antojitos") {
                return 160.0
            }
            if cat.contains("boutique") || cat.contains("boutique hotel") {
                return 180.0
            }
            if cat.contains("spa") || cat.contains("wellness") {
                return 170.0
            }
            if cat.contains("hotel") && cat.contains("restaurante") {
                return 150.0
            }
            if cat.contains("galería") || cat.contains("museo") {
                return 100.0
            }
            if cat.contains("taquería") || cat.contains("mercado") || cat.contains("puesto") {
                return 0.0  // Sin interés
            }
            return 30.0
            
        // 👨‍👩‍👧‍👦 Family with Kids - SOLO family-friendly
        case .familyWithKids:
            if cat.contains("parque") || cat.contains("park") {
                return 180.0
            }
            if cat.contains("zoo") || cat.contains("zoológico") {
                return 170.0
            }
            if cat.contains("acuario") || cat.contains("aquarium") {
                return 170.0
            }
            if cat.contains("museo") &&
               (cat.contains("niños") || cat.contains("infantil") || cat.contains("children")) {
                return 160.0
            }
            if cat.contains("heladería") || cat.contains("ice cream") || cat.contains("nieve") {
                return 140.0
            }
            if cat.contains("juegos") || cat.contains("playground") {
                return 150.0
            }
            if cat.contains("restaurante") && !cat.contains("bar") {
                return 90.0
            }
            if cat.contains("bar") || cat.contains("club") || cat.contains("cantina") {
                return 0.0  // Inapropiado
            }
            return 30.0
            
        // 💻 Digital Nomad - SOLO espacios de trabajo
        case .digitalNomad:
            if cat.contains("coworking") {
                return 200.0  // Perfecto
            }
            if cat.contains("café") || cat.contains("cafetería") {
                return 180.0
            }
            if cat.contains("biblioteca") || cat.contains("library") {
                return 160.0
            }
            if cat.contains("librería") && cat.contains("café") {
                return 150.0
            }
            if cat.contains("restaurante") {
                return 70.0
            }
            if cat.contains("parque") && cat.contains("wifi") {
                return 100.0
            }
            if cat.contains("bar") || cat.contains("club") {
                return 10.0
            }
            return 20.0
            
        // 💼 Business Traveler - SOLO profesional
        case .businessTraveler:
            if cat.contains("coworking") {
                return 140.0
            }
            if cat.contains("restaurante") && !cat.contains("taquería") {
                return 150.0
            }
            if cat.contains("hotel") && cat.contains("restaurante") {
                return 130.0
            }
            if cat.contains("café") || cat.contains("cafetería") {
                return 120.0
            }
            if cat.contains("bar") && !cat.contains("barbería") {
                return 90.0
            }
            if cat.contains("museo") || cat.contains("parque") {
                return 30.0
            }
            return 10.0
            
        // 📸 Casual Tourist - Balanceado
        case .casualTourist:
            if cat.contains("museo") || cat.contains("museum") {
                return 110.0
            }
            if cat.contains("mercado") || cat.contains("market") {
                return 120.0
            }
            if cat.contains("parque") || cat.contains("park") {
                return 100.0
            }
            if cat.contains("restaurante") {
                return 90.0
            }
            if cat.contains("iglesia") || cat.contains("church") {
                return 85.0
            }
            if cat.contains("tienda") || cat.contains("souvenir") {
                return 80.0
            }
            if cat.contains("monumento") {
                return 95.0
            }
            return 60.0
            
        // 🗺️ Local Explorer - SOLO experiencias locales
        case .localExplorer:
            if cat.contains("mercado") || cat.contains("market") {
                return 160.0
            }
            if cat.contains("taquería") || cat.contains("antojitos") {
                return 150.0
            }
            if cat.contains("café") && !cat.contains("starbucks") {
                return 130.0
            }
            if cat.contains("bar") && !cat.contains("barbería") && !cat.contains("cadena") {
                return 120.0
            }
            if cat.contains("cantina") {
                return 140.0
            }
            if cat.contains("parque") {
                return 100.0
            }
            if cat.contains("museo") || cat.contains("galería") {
                return 40.0
            }
            if cat.contains("restaurante") && !cat.contains("taquería") {
                return 50.0
            }
            return 70.0
        }
    }
    
    // MARK: - 🆕 Función de Scoring Mejorada
    private static func calculatePlaceScore(
        placeData: PlaceData,
        userLocation: CLLocation,
        userInterests: Set<LocationType>,
        userArchetype: UserArchetype?
    ) -> Double {
        var score = 0.0
        
        // 1. ⭐ Score por arquetipo (PRIORIDAD MÁXIMA: hasta 750 puntos!)
        let archetypeBonus = getArchetypeBonus(
            category: placeData.business_category,
            archetype: userArchetype
        )
        score += archetypeBonus * 1.5  // Multiplicador para dar más peso
        
        // 🆕 BOOST EXTRA para categorías premium según arquetipo
        if let cat = placeData.business_category?.lowercased() {
            if userArchetype == .sportsFanatic {
                if cat.contains("estadio") || cat.contains("stadium") {
                    score += 300.0  // ⚽ BOOST MASIVO para estadios
                }
                if cat.contains("arena") {
                    score += 200.0
                }
            }
            if userArchetype == .artHistoryBuff {
                if cat.contains("museo") || cat.contains("museum") {
                    score += 250.0  // 🎨 BOOST para museos
                }
                if cat.contains("galería") {
                    score += 200.0
                }
            }
            if userArchetype == .gourmetFoodie {
                if cat.contains("restaurante") &&
                   !cat.contains("taquería") &&
                   !cat.contains("antojitos") {
                    score += 150.0  // 🍽️ BOOST para restaurantes elegantes
                }
            }
        }
        
        // 2. Score por distancia (máximo 80 puntos - reducido)
        if let lat = Double(placeData.lat), let lng = Double(placeData.lng) {
            let placeLocation = CLLocation(latitude: lat, longitude: lng)
            let distance = userLocation.distance(from: placeLocation) / 1000.0
            score += max(0, 80 - (distance * 8))
        }
        
        // 3. Score por rating (máximo 80 puntos - reducido)
        if let rating = Double(placeData.rating), rating > 0 {
            score += rating * 16
        }
        
        // 4. Score por prioridad (máximo 70 puntos - reducido)
        if let priority = placeData.priority, let priorityValue = Double(priority) {
            score += priorityValue * 7
        }
        
        // 5. Score por peso de recomendación (máximo 100 puntos - reducido)
        if let weight = placeData.recommendation_weight, let weightValue = Double(weight) {
            score += weightValue * 10
        }
        
        // 6. Score básico por intereses (máximo 40 puntos - reducido)
        let category = mapTypeFromCategory(placeData.business_category)
        if userInterests.contains(category) {
            score += 40
        }
        
        // 7. Score extra por cercanía a estadio (máximo 100 puntos - aumentado)
        if placeData.near_stadium == "YES" && userArchetype == .sportsFanatic {
            score += 100.0  // ⚽ DOBLE bonus si está cerca de estadio
        }
        
        return score
    }

    // MARK: - Build Full Day Itinerary
    private static func buildFullDayItinerary(
        startTime: Date,
        endTime: Date,
        userLocation: CLLocation,
        recommendedDenueIDs: [String],
        userInterests: Set<LocationType>,
        userArchetype: UserArchetype?,
        existingEvents: [Event]
    ) -> SmartItinerarySuggestion? {
        
        guard let denueCache = denueIDCache else {
            logger.error("DENUE cache not loaded")
            return nil
        }
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        
        logger.debug("Building full day itinerary from \(startHour):00 to 22:00")
        
        // Scoring y ordenamiento
        var validPlaces = recommendedDenueIDs.compactMap { denueID -> (id: String, data: PlaceData, score: Double)? in
            guard let data = denueCache[denueID] else { return nil }
            guard isAllowedCategory(data.business_category, website: data.website, name: data.name) else { return nil }
            let score = calculatePlaceScore(placeData: data, userLocation: userLocation, userInterests: userInterests, userArchetype: userArchetype)
            return (denueID, data, score)
        }
        
        validPlaces.sort { $0.score > $1.score }
        
        guard !validPlaces.isEmpty else {
            logger.warning("No valid places for full day itinerary")
            return nil
        }
        
        if let archetype = userArchetype {
            logger.info("🎯 Building full day for: \(archetype.displayName)")
        }
        
        // Separar lugares de comida vs atracciones
        var foodPlaces = validPlaces.filter { isFood($0.data.business_category) }
        var attractionPlaces = validPlaces.filter { !isFood($0.data.business_category) }
        
        // 🆕 ASEGURAR que tenemos suficientes lugares de comida
        if foodPlaces.count < 3 {
            logger.warning("⚠️ Only \(foodPlaces.count) food places! Need at least 3 for full day")
            // Buscar más lugares de comida cercanos
            let additionalFood = denueCache.values
                .filter { place in
                    isFood(place.business_category) &&
                    isAllowedCategory(place.business_category, website: place.website, name: place.name)
                }
                .compactMap { place -> (id: String, data: PlaceData, score: Double)? in
                    guard let lat = Double(place.lat), let lng = Double(place.lng) else { return nil }
                    let loc = CLLocation(latitude: lat, longitude: lng)
                    let dist = userLocation.distance(from: loc) / 1000.0
                    guard dist <= 15.0 else { return nil }  // Radio ampliado
                    let score = calculatePlaceScore(placeData: place, userLocation: userLocation, userInterests: userInterests, userArchetype: userArchetype)
                    return (place.denue_id ?? place.place_id, place, score)
                }
                .sorted { $0.score > $1.score }
                .prefix(5)
            
            foodPlaces.append(contentsOf: additionalFood)
            logger.info("✅ Added \(additionalFood.count) more food places, total: \(foodPlaces.count)")
        }
        
        var stops: [ItineraryStop] = []
        var currentTime = startTime
        var currentLocation = userLocation
        var mealStops: [MealType: ItineraryStop] = [:]
        
        let mealSchedule = planMealsForDay(startHour: startHour, endHour: 22)
        logger.debug("Planned \(mealSchedule.count) meals: \(mealSchedule.map { $0.type.rawValue })")
        
        // 🆕 ESTRATEGIA: Primero agregar TODAS las comidas planeadas
        for meal in mealSchedule {
            let mealTime = calendar.date(bySetting: .hour, value: meal.hour, of: currentTime)!
            
            guard mealTime >= currentTime && mealTime < endTime else {
                logger.debug("⏩ Skipping \(meal.type.rawValue) - fuera de rango")
                continue
            }
            
            if let foodPlace = findNearestPlace(from: currentLocation, candidates: foodPlaces, maxDistance: 12.0) {
                let mealDuration: TimeInterval = meal.type == .snack ? 30*60 : 45*60
                
                let stop = createStop(
                    placeData: foodPlace.data,
                    arrivalTime: mealTime,
                    duration: mealDuration,
                    previousLocation: currentLocation,
                    mealType: meal.type
                )
                
                stops.append(stop)
                mealStops[meal.type] = stop
                currentTime = stop.departureTime.addingTimeInterval(15*60)
                currentLocation = CLLocation(
                    latitude: Double(foodPlace.data.lat) ?? 0,
                    longitude: Double(foodPlace.data.lng) ?? 0
                )
                foodPlaces.removeAll { $0.id == foodPlace.id }
                
                logger.info("✅ Added \(meal.type.rawValue) at \(meal.hour):00")
            } else {
                logger.warning("⚠️ Could not find food place for \(meal.type.rawValue)")
            }
        }
        
        // Luego llenar con atracciones entre comidas
        let sortedStops = stops.sorted { $0.arrivalTime < $1.arrivalTime }
        var finalStops: [ItineraryStop] = []
        
        currentTime = startTime
        currentLocation = userLocation
        
        for (index, mealStop) in sortedStops.enumerated() {
            // Agregar atracciones antes de esta comida
            while currentTime < mealStop.arrivalTime.addingTimeInterval(-45*60) {
                let timeUntilMeal = mealStop.arrivalTime.timeIntervalSince(currentTime)
                guard timeUntilMeal >= 60*60 else { break }  // Al menos 1 hora
                
                if let nextPlace = findNearestPlace(from: currentLocation, candidates: attractionPlaces, maxDistance: 8.0) {
                    let activityDuration: TimeInterval = min(90*60, timeUntilMeal - 30*60)
                    
                    let stop = createStop(
                        placeData: nextPlace.data,
                        arrivalTime: currentTime,
                        duration: activityDuration,
                        previousLocation: currentLocation,
                        mealType: nil
                    )
                    
                    finalStops.append(stop)
                    currentTime = stop.departureTime.addingTimeInterval(15*60)
                    currentLocation = CLLocation(
                        latitude: Double(nextPlace.data.lat) ?? 0,
                        longitude: Double(nextPlace.data.lng) ?? 0
                    )
                    attractionPlaces.removeAll { $0.id == nextPlace.id }
                } else {
                    break
                }
            }
            
            // Agregar la comida
            finalStops.append(mealStop)
            currentTime = mealStop.departureTime.addingTimeInterval(15*60)
            currentLocation = CLLocation(
                latitude: Double(mealStop.placeData.lat) ?? 0,
                longitude: Double(mealStop.placeData.lng) ?? 0
            )
        }
        
        // Agregar más atracciones después de la última comida
        while currentTime < endTime && !attractionPlaces.isEmpty {
            let timeUntilEnd = endTime.timeIntervalSince(currentTime)
            guard timeUntilEnd >= 45*60 else { break }
            
            if let nextPlace = findNearestPlace(from: currentLocation, candidates: attractionPlaces, maxDistance: 8.0) {
                let activityDuration: TimeInterval = min(90*60, timeUntilEnd - 15*60)
                
                let stop = createStop(
                    placeData: nextPlace.data,
                    arrivalTime: currentTime,
                    duration: activityDuration,
                    previousLocation: currentLocation,
                    mealType: nil
                )
                
                guard stop.departureTime <= endTime else { break }
                
                finalStops.append(stop)
                currentTime = stop.departureTime.addingTimeInterval(15*60)
                currentLocation = CLLocation(
                    latitude: Double(nextPlace.data.lat) ?? 0,
                    longitude: Double(nextPlace.data.lng) ?? 0
                )
                attractionPlaces.removeAll { $0.id == nextPlace.id }
            } else {
                break
            }
        }
        
        guard !finalStops.isEmpty else {
            logger.warning("No stops created for full day")
            return nil
        }
        
        finalStops.sort { $0.arrivalTime < $1.arrivalTime }
        
        let totalDistance = calculateTotalDistance(stops: finalStops)
        let actualDuration = finalStops.last!.departureTime.timeIntervalSince(finalStops.first!.arrivalTime)
        
        let mealCount = finalStops.filter { $0.mealType != nil }.count
        let attractionCount = finalStops.filter { $0.mealType == nil }.count
        
        logger.info("Full day itinerary: \(finalStops.count) stops (\(mealCount) meals, \(attractionCount) attractions), \(String(format: "%.1f", totalDistance))km, \(Int(actualDuration/3600))h")
        logger.info("Meals included: \(mealStops.keys.map { $0.rawValue }.joined(separator: ", "))")
        
        return SmartItinerarySuggestion(
            places: finalStops,
            totalDuration: actualDuration,
            totalDistance: totalDistance,
            mealStops: mealStops,
            itineraryType: .extended
        )
    }
    private static func planMealsForDay(startHour: Int, endHour: Int) -> [(hour: Int, type: MealType)] {
        var meals: [(hour: Int, type: MealType)] = []
        
        // Desayuno (7-10)
        if startHour <= 10 {
            meals.append((max(startHour, 8), .breakfast))
        }
        
        // Comida (13-15) - PRIORIDAD ALTA
        if startHour <= 15 && endHour >= 13 {
            let lunchHour = max(startHour, 13)
            if lunchHour <= 15 {
                meals.append((lunchHour, .lunch))
            }
        }
        
        // Snack (16-18) - NUEVO: Más flexible
        if endHour >= 17 {
            let snackHour = max(startHour + 1, 17)  // Al menos 1 hora después de inicio
            if snackHour <= 18 && snackHour < endHour {
                meals.append((snackHour, .snack))
            }
        }
        
        // Cena (19-21) - NUEVO: Más flexible
        if endHour >= 19 {
            let dinnerHour = max(startHour + 2, 20)  // Al menos 2 horas después de inicio
            if dinnerHour <= 21 && dinnerHour < endHour {
                meals.append((dinnerHour, .dinner))
            }
        }
        
        print("📅 Meals planned: \(meals.map { "\($0.type.rawValue) @ \($0.hour):00" }.joined(separator: ", "))")
        return meals
    }
    // MARK: - Build Smart Itinerary
    private static func buildSmartItinerary(
        startTime: Date,
        endTime: Date,
        userLocation: CLLocation,
        recommendedDenueIDs: [String],
        userInterests: Set<LocationType>,
        userArchetype: UserArchetype?
    ) -> SmartItinerarySuggestion? {

        guard let denueCache = denueIDCache else {
            logger.error("DENUE cache not loaded")
            return nil
        }

        let calendar = Calendar.current
        let slotDuration = endTime.timeIntervalSince(startTime)
        let startHour = calendar.component(.hour, from: startTime)
        let durationMinutes = Int(slotDuration / 60)

        let itineraryType: ItineraryType
        let targetStops: Int
        let stopDuration: TimeInterval

        switch durationMinutes {
        case 0..<30:
            itineraryType = .quickBite
            targetStops = 1
            stopDuration = 15 * 60
        case 30..<60:
            itineraryType = .express
            targetStops = 1
            stopDuration = 25 * 60
        case 60..<120:
            itineraryType = .short
            targetStops = 2
            stopDuration = 30 * 60
        case 120..<240:
            itineraryType = .standard
            targetStops = 3
            stopDuration = 40 * 60
        default:
            itineraryType = .extended
            targetStops = 5
            stopDuration = 45 * 60
        }

        logger.debug("Target: \(targetStops) stops, \(Int(stopDuration/60)) min each")

        // ✅ USAR SCORING MEJORADO
        var validPlaces = recommendedDenueIDs.compactMap { denueID -> (id: String, data: PlaceData, score: Double)? in
            guard let data = denueCache[denueID] else { return nil }

            guard isAllowedCategory(data.business_category,
                                   website: data.website,
                                   name: data.name) else {
                return nil
            }

            let score = calculatePlaceScore(
                placeData: data,
                userLocation: userLocation,
                userInterests: userInterests,
                userArchetype: userArchetype
            )

            return (denueID, data, score)
        }

        validPlaces.sort { $0.score > $1.score }
        logger.debug("Valid places: \(validPlaces.count), Top score: \(validPlaces.first?.score ?? 0)")
        
        // Log top recommendations con detalles de scoring
        if !validPlaces.isEmpty {
            if let archetype = userArchetype {
                logger.info("🎯 Building itinerary for: \(archetype.displayName)")
            }
            logger.debug("Top 5 recommendations with scores:")
            for (index, place) in validPlaces.prefix(5).enumerated() {
                let archetypeBonus = getArchetypeBonus(category: place.data.business_category, archetype: userArchetype)
                logger.debug("  \(index + 1). \(place.data.name)")
                logger.debug("      Category: \(place.data.business_category ?? "N/A")")
                logger.debug("      Total Score: \(Int(place.score)) (Archetype: \(Int(archetypeBonus * 1.5)))")
            }
        }

        guard !validPlaces.isEmpty else {
            logger.warning("No valid places from ML. Using fallback.")
            return buildFallbackItinerary(
                startTime: startTime,
                endTime: endTime,
                userLocation: userLocation,
                userInterests: userInterests,
                userArchetype: userArchetype,
                itineraryType: itineraryType
            )
        }

        var foodPlaces = validPlaces.filter { isFood($0.data.business_category) }
        var attractionPlaces = validPlaces.filter { !isFood($0.data.business_category) }

        var stops: [ItineraryStop] = []
        var currentTime = startTime
        var currentLocation = userLocation
        var mealStops: [MealType: ItineraryStop] = [:]

        let needsMeal = shouldIncludeMeal(startHour: startHour, duration: slotDuration, itineraryType: itineraryType)

        if needsMeal, let mealType = getMealType(for: startHour, duration: slotDuration) {
            logger.debug("Adding meal: \(mealType.rawValue)")

            if let foodPlace = findNearestPlace(from: currentLocation, candidates: foodPlaces, maxDistance: 10.0) {
                let mealDuration: TimeInterval = mealType == .snack ? 20*60 : stopDuration

                let stop = createStop(
                    placeData: foodPlace.data,
                    arrivalTime: currentTime,
                    duration: mealDuration,
                    previousLocation: currentLocation,
                    mealType: mealType
                )

                stops.append(stop)
                mealStops[mealType] = stop
                currentTime = stop.departureTime
                currentLocation = CLLocation(
                    latitude: Double(foodPlace.data.lat) ?? 0,
                    longitude: Double(foodPlace.data.lng) ?? 0
                )
                foodPlaces.removeAll { $0.id == foodPlace.id }
            }
        }

        let remainingStops = targetStops - stops.count

        for _ in 0..<remainingStops {
            guard !attractionPlaces.isEmpty else { break }

            guard let nextPlace = findNearestPlace(
                from: currentLocation,
                candidates: attractionPlaces,
                maxDistance: 8.0
            ) else { break }

            let stop = createStop(
                placeData: nextPlace.data,
                arrivalTime: currentTime,
                duration: stopDuration,
                previousLocation: currentLocation,
                mealType: nil
            )

            guard stop.departureTime <= endTime else { break }

            stops.append(stop)
            currentTime = stop.departureTime
            currentLocation = CLLocation(
                latitude: Double(nextPlace.data.lat) ?? 0,
                longitude: Double(nextPlace.data.lng) ?? 0
            )
            attractionPlaces.removeAll { $0.id == nextPlace.id }
        }

        guard !stops.isEmpty else {
            logger.warning("No stops created, using fallback")
            return buildFallbackItinerary(
                startTime: startTime,
                endTime: endTime,
                userLocation: userLocation,
                userInterests: userInterests,
                userArchetype: userArchetype,
                itineraryType: itineraryType
            )
        }

        stops.sort { $0.arrivalTime < $1.arrivalTime }

        let totalDistance = calculateTotalDistance(stops: stops)
        let totalDuration = stops.last!.departureTime.timeIntervalSince(stops.first!.arrivalTime)

        logger.info("Built \(itineraryType) itinerary: \(stops.count) stops, \(String(format: "%.1f", totalDistance))km")

        return SmartItinerarySuggestion(
            places: stops,
            totalDuration: totalDuration,
            totalDistance: totalDistance,
            mealStops: mealStops,
            itineraryType: itineraryType
        )
    }
    
    // MARK: - Fallback Itinerary
    private static func buildFallbackItinerary(
        startTime: Date,
        endTime: Date,
        userLocation: CLLocation,
        userInterests: Set<LocationType>,
        userArchetype: UserArchetype?,
        itineraryType: ItineraryType
    ) -> SmartItinerarySuggestion? {
        
        guard let denueCache = denueIDCache else { return nil }
        
        logger.info("Using fallback: nearby places")
        
        // 🆕 Si es Sports Fanatic, buscar estadios/arenas primero
        if userArchetype == .sportsFanatic {
            logger.info("⚽ Sports Fanatic: Searching for stadiums/arenas first...")
            
            let stadiums = denueCache.values
                .filter { place in
                    guard let cat = place.business_category?.lowercased() else { return false }
                    return cat.contains("estadio") || cat.contains("stadium") ||
                           cat.contains("arena") || cat.contains("campo deportivo")
                }
                .compactMap { place -> (id: String, data: PlaceData, distance: Double)? in
                    guard let lat = Double(place.lat),
                          let lng = Double(place.lng) else { return nil }
                    let loc = CLLocation(latitude: lat, longitude: lng)
                    let dist = userLocation.distance(from: loc) / 1000.0
                    guard dist <= 30.0 else { return nil }  // Búsqueda más amplia
                    return (place.denue_id ?? place.place_id, place, dist)
                }
                .sorted { $0.distance < $1.distance }
            
            if !stadiums.isEmpty {
                logger.info("Found \(stadiums.count) stadiums/arenas nearby!")
                let stadiumIDs = stadiums.prefix(10).map { $0.id }
                return buildSmartItinerary(
                    startTime: startTime,
                    endTime: endTime,
                    userLocation: userLocation,
                    recommendedDenueIDs: stadiumIDs,
                    userInterests: userInterests,
                    userArchetype: userArchetype
                )
            }
        }
        
        // 🆕 Si es Art & History Buff, buscar museos/galerías primero
        if userArchetype == .artHistoryBuff {
            logger.info("🎨 Art Buff: Searching for museums/galleries first...")
            
            let culturalSites = denueCache.values
                .filter { place in
                    guard let cat = place.business_category?.lowercased() else { return false }
                    return cat.contains("museo") || cat.contains("museum") ||
                           cat.contains("galería") || cat.contains("gallery") ||
                           cat.contains("monumento") || cat.contains("monument")
                }
                .compactMap { place -> (id: String, data: PlaceData, distance: Double)? in
                    guard let lat = Double(place.lat),
                          let lng = Double(place.lng) else { return nil }
                    let loc = CLLocation(latitude: lat, longitude: lng)
                    let dist = userLocation.distance(from: loc) / 1000.0
                    guard dist <= 25.0 else { return nil }
                    return (place.denue_id ?? place.place_id, place, dist)
                }
                .sorted { $0.distance < $1.distance }
            
            if !culturalSites.isEmpty {
                logger.info("Found \(culturalSites.count) cultural sites nearby!")
                let siteIDs = culturalSites.prefix(10).map { $0.id }
                return buildSmartItinerary(
                    startTime: startTime,
                    endTime: endTime,
                    userLocation: userLocation,
                    recommendedDenueIDs: siteIDs,
                    userInterests: userInterests,
                    userArchetype: userArchetype
                )
            }
        }
        
        // Fallback normal para otros arquetipos
        let nearbyPlaces = denueCache.values
            .compactMap { place -> (id: String, data: PlaceData, score: Double)? in
                guard isAllowedCategory(place.business_category,
                                       website: place.website,
                                       name: place.name) else {
                    return nil
                }
                guard let lat = Double(place.lat),
                      let lng = Double(place.lng) else { return nil }
                let loc = CLLocation(latitude: lat, longitude: lng)
                let dist = userLocation.distance(from: loc) / 1000.0
                guard dist <= 15.0 else { return nil }
                
                // Calcular score con arquetipo
                let archetypeBonus = getArchetypeBonus(
                    category: place.business_category,
                    archetype: userArchetype
                )
                let distanceScore = max(0, 100 - (dist * 10))
                let totalScore = (archetypeBonus * 1.5) + distanceScore
                
                return (place.denue_id ?? place.place_id, place, totalScore)
            }
            .sorted { $0.score > $1.score }
            .prefix(100)
        
        logger.info("Fallback found \(nearbyPlaces.count) nearby places")
        guard !nearbyPlaces.isEmpty else { return nil }
        
        let ids = nearbyPlaces.map { $0.id }
        return buildSmartItinerary(
            startTime: startTime,
            endTime: endTime,
            userLocation: userLocation,
            recommendedDenueIDs: ids,
            userInterests: userInterests,
            userArchetype: userArchetype
        )
    }
    
    // MARK: - Helper Functions
    private static func shouldIncludeMeal(startHour: Int, duration: TimeInterval, itineraryType: ItineraryType) -> Bool {
        let hours = Int(duration / 3600)
        if itineraryType == .quickBite { return true }
        if (startHour >= 7 && startHour <= 11) ||
           (startHour >= 12 && startHour <= 17) ||
           (startHour >= 18 && startHour <= 23) {
            return true
        }
        return hours >= 2
    }
    
    private static func getMealType(for startHour: Int, duration: TimeInterval) -> MealType? {
        let hours = Int(duration / 3600)
        let endHour = startHour + hours
        if startHour >= 7 && startHour <= 11 { return .breakfast }
        if startHour >= 12 && startHour <= 17 { return .lunch }
        if startHour >= 18 && startHour <= 23 { return .dinner }
        if duration < 3600 { return .snack }
        return nil
    }
    
    private static func isFood(_ category: String?) -> Bool {
        guard let c = category?.lowercased() else { return false }
        let foodKeywords = [
            "restaurante", "restaurantes", "taquería", "taqueria", "taqueros",
            "comida", "café", "cafe", "cafetería", "panadería", "panaderia",
            "cocina", "comedor", "mariscos", "carnicería", "carniceria",
            "antojitos", "dulcería", "dulceria", "bar", "food"
        ]
        for kw in foodKeywords {
            if c.contains(kw) {
                return kw != "bar" || !c.contains("barbería")
            }
        }
        return false
    }
    
    private static func findNearestPlace(
        from location: CLLocation,
        candidates: [(id: String, data: PlaceData, score: Double)],
        maxDistance: Double
    ) -> (id: String, data: PlaceData, score: Double)? {
        return candidates
            .map { (place: $0, distance: distanceToPlace($0.data, from: location)) }
            .filter { $0.distance <= maxDistance * 1000 }
            .sorted { place1, place2 in
                if abs(place1.place.score - place2.place.score) < 10 {
                    return place1.distance < place2.distance
                }
                return place1.place.score > place2.place.score
            }
            .first?.place
    }
    
    private static func distanceToPlace(_ place: PlaceData, from location: CLLocation) -> Double {
        guard let lat = Double(place.lat),
              let lng = Double(place.lng) else { return .infinity }
        let placeLocation = CLLocation(latitude: lat, longitude: lng)
        return location.distance(from: placeLocation)
    }
    
    private static func createStop(
        placeData: PlaceData,
        arrivalTime: Date,
        duration: TimeInterval,
        previousLocation: CLLocation,
        mealType: MealType?
    ) -> ItineraryStop {
        let lat = Double(placeData.lat) ?? 0
        let lng = Double(placeData.lng) ?? 0
        let placeLocation = CLLocation(latitude: lat, longitude: lng)
        let travelTime = previousLocation.distance(from: placeLocation) / 1000 * 5 * 60
        let departureTime = arrivalTime.addingTimeInterval(duration)
        
        let mapLocation = MapLocation(
            id: placeData.place_id,
            denueID: placeData.denue_id ?? placeData.place_id,
            name: placeData.name,
            type: mapTypeFromCategory(placeData.business_category),
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            description: placeData.primary_type,
            imageName: "placeholder_location",
            promotesWomenInSports: false,
            address: placeData.formatted_address,
            phoneNumber: placeData.phone_national,
            website: placeData.website
        )
        
        return ItineraryStop(
            place: mapLocation,
            placeData: placeData,
            arrivalTime: arrivalTime,
            departureTime: departureTime,
            travelTimeFromPrevious: travelTime,
            suggestedDuration: duration,
            mealType: mealType
        )
    }
    
    private static func mapTypeFromCategory(_ category: String?) -> LocationType {
        guard let c = category?.lowercased() else { return .others }
        if isFood(category) { return .food }
        if c.contains("cultural") || c.contains("museo") { return .cultural }
        if c.contains("tienda") || c.contains("shop") || c.contains("souvenir") { return .shop }
        if c.contains("entretenimiento") || (c.contains("bar") && !c.contains("barbería")) { return .entertainment }
        if c.contains("estadio") || c.contains("stadium") { return .stadium }
        return .others
    }
    
    private static func calculateTotalDistance(stops: [ItineraryStop]) -> Double {
        return stops.reduce(0) { $0 + $1.travelTimeFromPrevious / 60 / 5 }
    }
    
    // MARK: - ML Recommendations
    private static func getMLRecommendations(
        for user: User,
        from allLocations: [MapLocation],
        userLocation: CLLocation
    ) -> [String] {
        
        guard let denueCache = denueIDCache else {
            logger.error("DENUE cache not available for ML recommendations")
            return []
        }
        
        do {
            let config = MLModelConfiguration()
            let model = try PlaceMartha(configuration: config)
            
            let interactionHistory: [String: Double] = Dictionary(
                uniqueKeysWithValues: user.visits.compactMap { visit in
                    let denueID = visit.location.denueID
                    return (denueID, Double(visit.rating))
                }
            )
            
            logger.debug("User history: \(interactionHistory.count) interactions")
            
            let nearbyLocations = allLocations.filter { location in
                let placeLocation = CLLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                let distance = userLocation.distance(from: placeLocation) / 1000.0
                return distance <= 20.0
            }
            
            logger.debug("Nearby locations: \(nearbyLocations.count) within 20km")
            
            let candidateItems: [String]
            if interactionHistory.isEmpty, user.archetype != nil {
                logger.info("Using archetype: \(user.archetype!.displayName)")
                candidateItems = nearbyLocations
                    .filter { user.interests.contains($0.type) }
                    .map { $0.denueID }
            } else {
                candidateItems = nearbyLocations.map { $0.denueID }
            }
            
            guard !candidateItems.isEmpty else {
                logger.warning("No candidate items, using all locations")
                return allLocations.map { $0.denueID }.shuffled().prefix(50).map { $0 }
            }
            
            let input = PlaceMarthaInput(items: interactionHistory, k: 200)
            let output = try model.prediction(input: input)
            
            logger.info("ML returned \(output.recommendations.count) recommendations")
            
            // ⭐ CLAVE: Re-ordenar recomendaciones del ML usando scoring por arquetipo
            let rerankedRecommendations = output.recommendations.compactMap { denueID -> (id: String, score: Double)? in
                guard let placeData = denueCache[denueID] else { return nil }
                
                let archetypeScore = getArchetypeBonus(
                    category: placeData.business_category,
                    archetype: user.archetype
                )
                
                // Combinar score base del ML con bonus de arquetipo
                let baseScore = 100.0 // Score base del ML
                let totalScore = baseScore + archetypeScore
                
                return (denueID, totalScore)
            }
            .sorted { $0.score > $1.score }
            .map { $0.id }
            
            logger.info("Re-ranked \(rerankedRecommendations.count) places by archetype")
            if let archetype = user.archetype {
                logger.info("Top 5 for \(archetype.displayName):")
                for (i, denueID) in rerankedRecommendations.prefix(5).enumerated() {
                    if let place = denueCache[denueID] {
                        logger.info("  \(i+1). \(place.name) - \(place.business_category ?? "N/A")")
                    }
                }
            }
            
            return rerankedRecommendations
            
        } catch {
            logger.error("ML prediction failed: \(error)")
            
            // Fallback con scoring por arquetipo
            return allLocations
                .compactMap { location -> (denueID: String, score: Double)? in
                    guard let placeData = denueCache[location.denueID] else { return nil }
                    
                    let placeLocation = CLLocation(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    let distance = userLocation.distance(from: placeLocation) / 1000.0
                    guard distance <= 15.0 else { return nil }
                    
                    let archetypeScore = getArchetypeBonus(
                        category: placeData.business_category,
                        archetype: user.archetype
                    )
                    
                    let distanceScore = max(0, 100 - (distance * 10))
                    let totalScore = archetypeScore + distanceScore
                    
                    return (location.denueID, totalScore)
                }
                .sorted { $0.score > $1.score }
                .prefix(50)
                .map { $0.denueID }
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
