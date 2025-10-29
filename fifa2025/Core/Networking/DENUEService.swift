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
    private let logger = Logger(subsystem: "com.fifa2025.TurismoLocalWC26", category: "DENUEService")
    
    // Cache for raw DENUEBusiness objects. Key will be a combination of grid and category.
    private let cache = CacheManager<[DENUEBusiness]>()

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
        self.apiToken = DENUEService.loadApiToken()
    }
    
    private static func loadApiToken() -> String {
        guard let url = Bundle.main.url(forResource: "ApiKeys", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let token = plist["DENUE_API_TOKEN"] as? String else {
            fatalError("Could not load API Token from ApiKeys.plist.")
        }
        return token
    }
    
    /// Fetches businesses for a SINGLE category. Checks cache first.
    func fetchBusinesses(for category: LocationType, gridKey: String, near coordinate: CLLocationCoordinate2D, radiusInMeters: Int) async throws -> [MapLocation] {
        guard !apiToken.isEmpty else {
            logger.error("API Token is missing.")
            throw APIError.invalidURL
        }

        let cacheKey = "\(gridKey)-\(category.rawValue)"

        if let cachedBusinesses = cache.getValue(forKey: cacheKey) {
            logger.debug("Cache hit for key: \(cacheKey).")
            return transformToMapLocations(cachedBusinesses)
        }
            
        logger.info("Cache miss for key: \(cacheKey). Fetching from network.")
            
        let categoryKeywords = keywords(for: category)
        let businessesForCategory = await fetchConcurrently(for: categoryKeywords, near: coordinate, radiusInMeters: radiusInMeters)
            
        let uniqueBusinesses = Array(Set(businessesForCategory))
        
        cache.setValue(uniqueBusinesses, forKey: cacheKey)
        logger.info("Fetched and cached \(uniqueBusinesses.count) businesses for key: \(cacheKey).")
        
        return transformToMapLocations(uniqueBusinesses)
    }
    
    /// Helper to run concurrent requests for a given list of keywords.
    private func fetchConcurrently(for keywords: [String], near coordinate: CLLocationCoordinate2D, radiusInMeters: Int) async -> [DENUEBusiness] {
        var allBusinesses: [DENUEBusiness] = []
        let batchSize = 3
        let keywordBatches = keywords.chunks(ofCount: batchSize)

        for batch in keywordBatches {
            let batchResult = await withTaskGroup(of: [DENUEBusiness].self, returning: [DENUEBusiness].self) { group in
                for query in batch {
                    group.addTask {
                        let urlString = "https://www.inegi.org.mx/app/api/denue/v1/consulta/buscar/\(query)/\(coordinate.latitude),\(coordinate.longitude)/\(radiusInMeters)/\(self.apiToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            
                            guard let url = URL(string: urlString) else { return [] }
                            
                            do {
                                var urlRequest = URLRequest(url: url)
                                urlRequest.timeoutInterval = 20.0
                                
                                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                                
                                guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                                    self.logger.warning("Invalid response for query: '\(query)'")
                                    return []
                                }
                                
                                return try JSONDecoder().decode([DENUEBusiness].self, from: data)
                            } catch {
                                self.logger.error("Request for query '\(query)' failed: \(error.localizedDescription)")
                                return []
                            }
                        }
                    }
                    
                    var collected: [DENUEBusiness] = []
                    for await result in group {
                        collected.append(contentsOf: result)
                    }
                    return collected
                }
                allBusinesses.append(contentsOf: batchResult)
            }
            return allBusinesses
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
            return [] // Or add default/fallback keywords if desired
        }
    }
    private func transformToMapLocations(_ businesses: [DENUEBusiness]) -> [MapLocation] {
        return businesses.compactMap { business -> MapLocation? in
            // Validar que latitude y longitude no estén vacíos
            guard
                !business.latitude.isEmpty,
                !business.longitude.isEmpty,
                let lat = Double(business.latitude),
                let lon = Double(business.longitude)
            else {
                logger.warning("Saltando negocio '\(business.name)' por coordenadas inválidas: [\(business.latitude), \(business.longitude)]")
                return nil
            }

            let locationType = mapBusinessTypeToLocationType(business.businessCategory)

            return MapLocation(
                id: business.id,
                denueID: business.id,
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

// ✅ ELIMINADA: Extensión redundante de Hashable
// DENUEBusiness ya conforma a Hashable en su definición original

extension Array {
    func chunks(ofCount size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
