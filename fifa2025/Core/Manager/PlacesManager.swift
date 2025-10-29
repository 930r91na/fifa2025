//
//  PlacesManager.swift
//  fifa2025
//
//  Created by Martha Heredia Andrade on 22/10/25.
//

import Foundation

class PlacesManager {
    private let apiKey = "AIzaSyBJ-zhzk6eACGtf7jjGNvzrA1Hxgg9h3Sk"
    private let baseURL = "https://places.googleapis.com/v1"
    private var allPlaces: Set<String> = []
    private var csvData: [String] = []
    
    // 🔥 HEADER CON COLUMNA "source" AL INICIO PARA COMPATIBILIDAD CON INEGI
    private let csvHeader = "source,primary_type,name,types,rating,user_ratings_total,price_level,price_range_min,price_range_max,lat,lng,photo_uri,opening_hours,website,phone_national,phone_international,google_maps_uri,formatted_address,business_category,denue_id"
    
    private let relevantTypes: Set<String> = [
        "stadium", "sports_complex", "sports_club", "bowling_alley", "gym",
        "fitness_center", "swimming_pool", "tennis_court", "soccer_field",
        "restaurant", "cafe", "bar", "night_club", "mexican_restaurant",
        "bakery", "meal_takeaway", "meal_delivery", "seafood_restaurant",
        "japanese_restaurant", "mediterranean_restaurant", "brunch_restaurant",
        "breakfast_restaurant", "steak_house", "brazilian_restaurant",
        "italian_restaurant", "chinese_restaurant", "american_restaurant",
        "fast_food_restaurant", "pizza_restaurant", "sandwich_shop",
        "ice_cream_shop", "coffee_shop", "food_court", "bar_and_grill",
        "amusement_park", "zoo", "aquarium", "casino", "movie_theater",
        "bowling_alley", "amusement_center", "arcade",
        "tourist_attraction", "museum", "art_gallery", "park", "shopping_mall",
        "historical_landmark", "church", "library", "concert_hall",
        "cultural_center", "event_venue", "performing_arts_theater",
        "monument", "national_park", "state_park", "convention_center",
        "auditorium", "city_hall", "courthouse", "embassy", "plaza",
        "hotel", "lodging", "resort_hotel", "extended_stay_hotel",
        "bed_and_breakfast", "guest_house", "hostel",
        "shopping_mall", "department_store", "clothing_store", "jewelry_store",
        "book_store", "electronics_store", "supermarket", "convenience_store",
        "spa", "beauty_salon", "hair_salon", "wedding_venue",
        "subway_station", "train_station", "bus_station", "airport",
        "transit_station", "light_rail_station"
    ]
    
    private let ignoredTypes: Set<String> = [
        "gas_station", "atm", "car_repair", "car_wash", "parking",
        "real_estate_agency", "lawyer", "accounting", "insurance_agency"
    ]
    
    func generateCSVTouristZones() async throws -> URL {
        allPlaces.removeAll()
        csvData = [csvHeader]
        
        print("🚀 INICIANDO ESCANEO GOOGLE PLACES - CIUDAD DE MÉXICO")
        print("📍 Fuente: Google Places API")
        print("🎯 Objetivo: Dataset premium con ratings, fotos y horarios\n")
        
        let megaGrid = generateComprehensiveGrid()
        var totalPlaces = 0
        let startTime = Date()
        
        for (index, zone) in megaGrid.enumerated() {
            let progress = Double(index + 1) / Double(megaGrid.count) * 100
            print("🔍 [\(index+1)/\(megaGrid.count)] [\(String(format: "%.1f", progress))%] \(zone.name)")
            
            do {
                let count = try await searchNearby(
                    lat: zone.lat,
                    lng: zone.lng,
                    radius: zone.radius
                )
                totalPlaces += count
                
                if count > 0 {
                    print("   ✅ +\(count) lugares | Total: \(allPlaces.count)")
                } else {
                    print("   ⚪ Sin lugares nuevos")
                }
                
                try await Task.sleep(nanoseconds: 250_000_000)
            } catch {
                print("   ❌ Error: \(error.localizedDescription)")
                continue
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("\n" + String(repeating: "=", count: 50))
        print("🎉 ESCANEO GOOGLE PLACES COMPLETADO")
        print(String(repeating: "=", count: 50))
        print("📊 Lugares únicos encontrados: \(allPlaces.count)")
        print("💾 Registros en CSV: \(csvData.count - 1)")
        print("⏱️ Tiempo total: \(String(format: "%.1f", duration / 60)) minutos")
        print("💰 Costo estimado: $\(String(format: "%.2f", Double(allPlaces.count) * 0.032)) USD")
        print(String(repeating: "=", count: 50) + "\n")
        
        return try saveCSV()
    }
    
    private func generateComprehensiveGrid() -> [(lat: Double, lng: Double, name: String, radius: Double)] {
        var zones: [(lat: Double, lng: Double, name: String, radius: Double)] = []
        
        let vipZones = [
            (19.4326, -99.1332, "Centro Histórico - Zócalo", 4000.0),
            (19.4343, -99.1331, "Centro - Catedral", 3000.0),
            (19.4350, -99.1420, "Centro - Alameda Central", 3500.0),
            (19.4250, -99.1500, "Centro - Bellas Artes", 3000.0),
            (19.4200, -99.1719, "Polanco - Masaryk", 4000.0),
            (19.4260, -99.1820, "Polanco - Antara", 3000.0),
            (19.4180, -99.1650, "Polanco - Parque Lincoln", 3000.0),
            (19.4483, -99.2065, "Chapultepec - Bosque", 5000.0),
            (19.4520, -99.1820, "Chapultepec - Museo Antropología", 3000.0),
            (19.4250, -99.2100, "Chapultepec - Auditorio", 3000.0),
            (19.4180, -99.1750, "Zona Rosa - Reforma", 3500.0),
            (19.4220, -99.1680, "Zona Rosa - Ángel", 3000.0),
            (19.3623, -99.1763, "Condesa - Parque México", 3500.0),
            (19.3650, -99.1850, "Condesa - Amsterdam", 3000.0),
            (19.3700, -99.1650, "Roma Norte", 3500.0),
            (19.3580, -99.1700, "Roma Sur", 3000.0),
            (19.3550, -99.1870, "Coyoacán - Centro", 4000.0),
            (19.3520, -99.1810, "Coyoacán - Jardín Centenario", 3000.0),
            (19.3500, -99.1750, "Coyoacán - Frida Kahlo", 3000.0),
            (19.3460, -99.1790, "San Ángel", 3500.0),
            (19.3470, -99.1890, "San Ángel - Bazar Sábado", 2500.0),
            (19.3600, -99.2740, "Santa Fe - Centro", 5000.0),
            (19.3650, -99.2650, "Santa Fe - Samara", 3500.0),
            (19.3570, -99.2700, "Santa Fe - Parque La Mexicana", 3000.0)
        ]
        
        let sportsZones = [
            (19.3029, -99.1504, "⚽ Estadio Azteca", 4000.0),
            (19.3000, -99.1550, "Estadio Azteca - Norte", 3000.0),
            (19.3050, -99.1450, "Estadio Azteca - Sur", 3000.0),
            (19.4110, -99.2007, "⚽ Estadio Azul", 3500.0),
            (19.4733, -99.2467, "⚽ Estadio CU", 4000.0),
            (19.4036, -99.1915, "Palacio de los Deportes", 3000.0),
            (19.4510, -99.1370, "Foro Sol/Autódromo", 4000.0),
            (19.4050, -99.0960, "Arena CDMX", 3000.0)
        ]
        
        let peripheralZones = [
            (19.4970, -99.1050, "Basílica de Guadalupe", 4000.0),
            (19.5100, -99.1200, "Villa de Guadalupe", 3500.0),
            (19.5200, -99.1500, "Lindavista", 3500.0),
            (19.4850, -99.1280, "La Villa - Mercado", 3000.0),
            (19.2800, -99.1790, "Tlalpan Centro", 4000.0),
            (19.2900, -99.1700, "Tlalpan - Parque Nacional", 3500.0),
            (19.2971, -99.1808, "Cuicuilco", 3500.0),
            (19.2600, -99.1550, "Tlalpan - Carretera Picacho", 3000.0),
            (19.2900, -99.1870, "Xochimilco Centro", 4000.0),
            (19.2750, -99.1020, "Xochimilco - Embarcadero", 3500.0),
            (19.4285, -99.0730, "Aeropuerto AICM", 5000.0),
            (19.4000, -99.0850, "Terminal Aérea", 3500.0),
            (19.3700, -99.0900, "Iztacalco", 3500.0),
            (19.3510, -99.0730, "Iztapalapa Norte", 3500.0),
            (19.3200, -99.0900, "Iztapalapa Centro", 3500.0),
            (19.3670, -99.2591, "Santa Fe - Samara", 3500.0),
            (19.3400, -99.2900, "Cuajimalpa", 3500.0)
        ]
        
        let commercialZones = [
            (19.3900, -99.1700, "Insurgentes Sur - Del Valle", 4000.0),
            (19.3750, -99.1750, "Insurgentes - WTC", 3500.0),
            (19.3920, -99.1730, "Del Valle Centro", 3000.0),
            (19.3688, -99.1812, "Universidad - Manacar", 3500.0),
            (19.3670, -99.1660, "Universidad - Plaza", 3000.0),
            (19.3600, -99.1645, "Cineteca Nacional", 2500.0),
            (19.4400, -99.2040, "Plaza Carso - Soumaya", 3500.0),
            (19.4420, -99.2065, "Nuevo Polanco", 3000.0)
        ]
        
        let additionalGrid = generateFillGrid()
        
        zones.append(contentsOf: vipZones)
        zones.append(contentsOf: sportsZones)
        zones.append(contentsOf: peripheralZones)
        zones.append(contentsOf: commercialZones)
        zones.append(contentsOf: additionalGrid)
        
        return zones
    }
    
    private func generateFillGrid() -> [(lat: Double, lng: Double, name: String, radius: Double)] {
        var grid: [(Double, Double, String, Double)] = []
        
        let latMin = 19.2
        let latMax = 19.6
        let lngMin = -99.35
        let lngMax = -99.0
        let gridSize = 0.04
        
        var lat = latMin
        var counter = 1
        
        while lat <= latMax {
            var lng = lngMin
            while lng <= lngMax {
                grid.append((lat, lng, "Grid-\(counter)", 3000.0))
                counter += 1
                lng += gridSize
            }
            lat += gridSize
        }
        
        return grid
    }
    
    private func searchNearby(lat: Double, lng: Double, radius: Double) async throws -> Int {
        let url = URL(string: "\(baseURL)/places:searchNearby")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.types,places.primaryType,places.rating,places.userRatingCount", forHTTPHeaderField: "X-Goog-FieldMask")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "maxResultCount": 20,
            "locationRestriction": [
                "circle": [
                    "center": ["latitude": lat, "longitude": lng],
                    "radius": radius
                ]
            ],
            "languageCode": "es"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: -1)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let places = json["places"] as? [[String: Any]] else {
            return 0
        }
        
        var newPlacesCount = 0
        
        for place in places {
            guard let id = place["id"] as? String,
                  !allPlaces.contains(id) else { continue }
            
            if let primaryType = place["primaryType"] as? String,
               shouldIncludePlace(primaryType: primaryType, types: place["types"] as? [String] ?? []) {
                
                let rating = place["rating"] as? Double ?? 0.0
                let userRatings = place["userRatingCount"] as? Int ?? 0
                
                let isStadium = primaryType == "stadium" || (place["types"] as? [String])?.contains("stadium") == true
                let isTransport = primaryType.contains("station") || primaryType.contains("airport")
                
                if isStadium || isTransport || rating >= 2.0 || userRatings >= 20 {
                    allPlaces.insert(id)
                    newPlacesCount += 1
                    
                    do {
                        try await getPlaceDetails(placeId: id, placeData: place)
                        try await Task.sleep(nanoseconds: 100_000_000)
                    } catch {
                        continue
                    }
                }
            }
        }
        
        return newPlacesCount
    }
    
    private func shouldIncludePlace(primaryType: String, types: [String]) -> Bool {
        if ignoredTypes.contains(primaryType) {
            return false
        }
        
        if primaryType == "stadium" || types.contains("stadium") {
            return true
        }
        
        if relevantTypes.contains(primaryType) {
            return true
        }
        
        for type in types {
            if relevantTypes.contains(type) && !ignoredTypes.contains(type) {
                return true
            }
        }
        
        return false
    }
    
    private func getPlaceDetails(placeId: String, placeData: [String: Any]) async throws {
        let url = URL(string: "\(baseURL)/places/\(placeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        let fieldMask = "displayName,types,primaryType,rating,userRatingCount,priceLevel,priceRange,location,photos,regularOpeningHours,websiteUri,nationalPhoneNumber,internationalPhoneNumber,googleMapsUri,formattedAddress"
        request.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "", code: -1)
        }
        
        // DATOS BÁSICOS
        let name = (json["displayName"] as? [String: Any])?["text"] as? String ?? "Sin nombre"
        let typesArray = json["types"] as? [String] ?? []
        let types = typesArray.joined(separator: "|")
        var primaryType = json["primaryType"] as? String ?? typesArray.first ?? "unknown"
        let rating = json["rating"] as? Double ?? 0.0
        let userRatingsTotal = json["userRatingCount"] as? Int ?? 0
        
        // PRECIO
        let priceLevel = json["priceLevel"] as? String ?? ""
        var priceRangeMin = ""
        var priceRangeMax = ""
        if let priceRange = json["priceRange"] as? [String: Any] {
            if let startPrice = priceRange["startPrice"] as? [String: Any],
               let units = startPrice["units"] as? String {
                priceRangeMin = units
            }
            if let endPrice = priceRange["endPrice"] as? [String: Any],
               let units = endPrice["units"] as? String {
                priceRangeMax = units
            }
        }
        
        // UBICACIÓN
        let location = json["location"] as? [String: Any]
        let lat = location?["latitude"] as? Double ?? 0.0
        let lng = location?["longitude"] as? Double ?? 0.0
        
        // DIRECCIÓN
        let formattedAddress = json["formattedAddress"] as? String ?? ""
        
        // FOTO
        var photoUri = ""
        if let photos = json["photos"] as? [[String: Any]],
           let firstPhoto = photos.first,
           let photoName = firstPhoto["name"] as? String {
            photoUri = "https://places.googleapis.com/v1/\(photoName)/media?maxWidthPx=800&maxHeightPx=800&key=\(apiKey)"
        }
        
        // HORARIOS
        var openingHours = ""
        if let regularHours = json["regularOpeningHours"] as? [String: Any],
           let weekdayDescriptions = regularHours["weekdayDescriptions"] as? [String] {
            openingHours = weekdayDescriptions.joined(separator: "; ")
        }
        
        // WEBSITE
        let websiteUri = json["websiteUri"] as? String ?? ""
        
        // TELÉFONOS
        let nationalPhone = json["nationalPhoneNumber"] as? String ?? ""
        let internationalPhone = json["internationalPhoneNumber"] as? String ?? ""
        
        // GOOGLE MAPS URI
        let googleMapsUri = json["googleMapsUri"] as? String ?? ""
        
        // FIX: Corregir primary_type para estadios
        if typesArray.contains("stadium") && primaryType != "stadium" {
            primaryType = "stadium"
        }
        
        let stadiumKeywords = ["estadio", "stadium", "arena", "foro sol", "palacio de los deportes", "autódromo"]
        let lowercaseName = name.lowercased()
        if stadiumKeywords.contains(where: { lowercaseName.contains($0) }) && primaryType != "stadium" {
            primaryType = "stadium"
        }
        
        // 🔥 CONSTRUIR FILA DEL CSV CON COLUMNA "source" = "GOOGLE"
        let row = [
            "GOOGLE",                           // source (NUEVO)
            escapeCSV(primaryType),             // primary_type
            escapeCSV(name),                    // name
            escapeCSV(types),                   // types
            String(rating),                     // rating
            String(userRatingsTotal),           // user_ratings_total
            escapeCSV(priceLevel),              // price_level
            priceRangeMin,                      // price_range_min
            priceRangeMax,                      // price_range_max
            String(lat),                        // lat
            String(lng),                        // lng
            escapeCSV(photoUri),                // photo_uri
            escapeCSV(openingHours),            // opening_hours
            escapeCSV(websiteUri),              // website
            escapeCSV(nationalPhone),           // phone_national
            escapeCSV(internationalPhone),      // phone_international
            escapeCSV(googleMapsUri),           // google_maps_uri
            escapeCSV(formattedAddress),        // formatted_address
            escapeCSV(primaryType),             // business_category (para compatibilidad)
            placeId                             // denue_id (en Google es el placeId)
        ]
        
        let csvRow = row.map { "\"\($0)\"" }.joined(separator: ",")
        csvData.append(csvRow)
    }
    
    private func escapeCSV(_ value: String) -> String {
        return value.replacingOccurrences(of: "\"", with: "\"\"")
    }
    
    private func saveCSV() throws -> URL {
        let filename = "google_places_dataset_\(Int(Date().timeIntervalSince1970)).csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        
        let csvString = csvData.joined(separator: "\n")
        try csvString.write(to: path, atomically: true, encoding: .utf8)
        
        return path
    }
}
