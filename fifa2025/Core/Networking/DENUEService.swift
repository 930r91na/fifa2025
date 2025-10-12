//
//  DENUEService.swift
//  fifa2025
//
//  Created by Georgina on 11/10/25.
//

import Foundation
import CoreLocation
import OSLog

class DENUEService {
    
    private let apiService: APIServiceProtocol
    private let apiToken: String
    
    // A specific logger for our service for better debugging
    private let logger = Logger(subsystem: "com.fifa2025.TurismoLocalWC26", category: "DENUEService")
    
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
        self.apiToken = DENUEService.loadApiToken()
    }
    
    // Securely loads the API token from the plist file.
    private static func loadApiToken() -> String {
        guard let url = Bundle.main.url(forResource: "ApiKeys", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let token = plist["DENUE_API_TOKEN"] as? String else {
            fatalError("Could not load API Token from ApiKeys.plist. Please ensure the file and key exist.")
        }
        return token
    }
    
    /// Fetches businesses for multiple categories concurrently, combines them, and removes duplicates.
    func fetchBusinesses(for categories: [LocationType], near coordinate: CLLocationCoordinate2D, radiusInMeters: Int = 2000) async throws -> [MapLocation] {
        guard !apiToken.isEmpty else {
            logger.error("API Token is missing. Cannot make a request.")
            throw APIError.invalidURL
        }

        // Use a Swift TaskGroup to run multiple network requests concurrently
        let allBusinesses: [DENUEBusiness] = await withTaskGroup(of: [DENUEBusiness].self, returning: [DENUEBusiness].self) { group in
            
            // Get all unique keywords from the selected categories
            let allKeywords = Set(categories.flatMap { keywords(for: $0) })
            
            for query in allKeywords {
                group.addTask {
                    let urlString = "https://www.inegi.org.mx/app/api/denue/v1/consulta/buscar/\(query)/\(coordinate.latitude),\(coordinate.longitude)/\(radiusInMeters)/\(self.apiToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    
                    guard let url = URL(string: urlString) else {
                        self.logger.warning("Failed to create a valid URL for query: \(query)")
                        return [] // Return an empty array for this specific failed task
                    }
                    
                    self.logger.info("Requesting businesses for query '\(query)'")
                    
                    do {
                        return try await self.apiService.request(url: url)
                    } catch {
                        self.logger.error("Failed to fetch businesses for query '\(query)': \(error.localizedDescription)")
                        return [] // Return an empty array on error to not fail the whole group
                    }
                }
            }
            
            // Collect results from all tasks
            var collectedBusinesses: [DENUEBusiness] = []
            for await businesses in group {
                collectedBusinesses.append(contentsOf: businesses)
            }
            return collectedBusinesses
        }
        
        // Remove duplicates using a Set and the business ID
        let uniqueBusinesses = Array(Set(allBusinesses))
        logger.info("Successfully fetched \(allBusinesses.count) raw entries, with \(uniqueBusinesses.count) unique businesses.")
        
        let mapLocations = transformToMapLocations(uniqueBusinesses)
        
        logger.info("Successfully transformed \(mapLocations.count) businesses into MapLocation models.")
        
        return mapLocations
    }

    /// Maps a LocationType to its corresponding DENUE API search keywords.
    private func keywords(for type: LocationType) -> [String] {
        switch type {
        case .food:
            return ["restaurantes", "cafeterías", "neverías", "taquerías", "pizzerías", "antojitos"]
        case .shop:
            return ["artesanías", "ropa", "calzado", "joyería"]
        case .cultural:
            return ["museos", "galerías de arte", "sitios históricos", "teatros"]
        case .stadium:
            return ["estadios"]
        case .entertainment:
            return ["bares", "centros nocturnos", "discotecas", "cines", "billares", "boliches"]
        case .souvenirs:
            return ["dulces", "regalos", "artículos religiosos"]
        case .others:
            return [] 
        }
    }
    
    private func transformToMapLocations(_ businesses: [DENUEBusiness]) -> [MapLocation] {
        return businesses.compactMap { business in
            guard let lat = Double(business.latitude), let lon = Double(business.longitude) else {
                logger.warning("Skipping business '\(business.name)' due to invalid coordinates.")
                return nil
            }
            
            let locationType = mapBusinessTypeToLocationType(business.businessCategory)
            
            return MapLocation(
                denueID: business.id, // Use the stable ID from the API
                name: business.name.capitalized,
                type: locationType,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                description: business.businessCategory,
                imageName: MockData.randomMockImage(), // Placeholder
                promotesWomenInSports: false, // This would require a separate data source
                address: business.address,
                phoneNumber: business.phoneNumber,
                website: business.website
            )
        }
    }
    
    /// Maps the detailed business category string from the API to our app's `LocationType`.
    private func mapBusinessTypeToLocationType(_ category: String) -> LocationType {
        let lowercasedCategory = category.lowercased()
        
        if keywords(for: .food).contains(where: lowercasedCategory.contains) {
            return .food
        } else if keywords(for: .entertainment).contains(where: lowercasedCategory.contains) {
            return .entertainment
        } else if keywords(for: .shop).contains(where: lowercasedCategory.contains) {
            return .shop
        } else if keywords(for: .souvenirs).contains(where: lowercasedCategory.contains) {
            return .souvenirs
        } else if keywords(for: .cultural).contains(where: lowercasedCategory.contains) {
            return .cultural
        } else if keywords(for: .stadium).contains(where: lowercasedCategory.contains) {
            return .stadium
        } else {
            return .others
        }
    }
}

// Add Hashable conformance to DENUEBusiness to allow for easy deduplication in a Set.
extension DENUEBusiness: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DENUEBusiness, rhs: DENUEBusiness) -> Bool {
        return lhs.id == rhs.id
    }
}
