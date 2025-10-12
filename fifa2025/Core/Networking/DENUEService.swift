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
    
    func fetchBusinesses(searchQuery: String = "restaurante", near coordinate: CLLocationCoordinate2D, radiusInMeters: Int = 1500) async throws -> [MapLocation] {
        guard !apiToken.isEmpty else {
            logger.error("API Token is missing. Cannot make a request.")
            throw APIError.invalidURL // Or a more specific error
        }

        // Construct the URL exactly as specified in the DENUE documentation
        let urlString = "https://www.inegi.org.mx/app/api/denue/v1/consulta/buscar/\(searchQuery)/\(coordinate.latitude),\(coordinate.longitude)/\(radiusInMeters)/\(apiToken)"

        guard let url = URL(string: urlString) else {
            logger.error("Failed to create a valid URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        logger.info("Requesting businesses from URL: \(url.absoluteString)")
        
        let denueBusinesses: [DENUEBusiness] = try await apiService.request(url: url)
        
        logger.debug("Successfully fetched \(denueBusinesses.count) raw business entries.")
        
        let mapLocations = transformToMapLocations(denueBusinesses)
        
        logger.info("Successfully transformed \(mapLocations.count) businesses into MapLocation models.")
        
        return mapLocations
    }
    
    private func transformToMapLocations(_ businesses: [DENUEBusiness]) -> [MapLocation] {
        return businesses.compactMap { business in
            guard let lat = Double(business.latitude), let lon = Double(business.longitude) else {
                // logger is not defined here, using print for now
                print("Skipping business '\(business.name)' due to invalid coordinates.")
                return nil
            }
            
            let locationType = mapBusinessTypeToLocationType(business.businessCategory)
            
            return MapLocation(
                name: business.name.capitalized,
                type: locationType,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                description: business.businessCategory,
                imageName: MockData.randomMockImage(),
                promotesWomenInSports: false,
                address: business.address,
                phoneNumber: business.phoneNumber,
                website: business.website
            )
        }
    }
    
    private func mapBusinessTypeToLocationType(_ category: String) -> LocationType {
        let lowercasedCategory = category.lowercased()
        if lowercasedCategory.contains("restaurante") || lowercasedCategory.contains("tacos") || lowercasedCategory.contains("alimentos") {
            return .food
        } else if lowercasedCategory.contains("comercio") || lowercasedCategory.contains("tienda") {
            return .shop
        } else if lowercasedCategory.contains("museo") || lowercasedCategory.contains("cultural") {
            return .cultural
        } else {
            return .others 
        }
    }
}
