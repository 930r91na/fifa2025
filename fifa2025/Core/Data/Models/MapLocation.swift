//
//  MapLocation.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation

// Enum for filtering categories
enum LocationType: String, CaseIterable, Identifiable {
    case food = "Food"
    case shop = "Shop"
    case cultural = "Cultural"
    case stadium = "Stadium"
    
    var id: String { self.rawValue }
    
    var sfSymbol: String {
        switch self {
        case .food:
            return "fork.knife"
        case .shop:
            return "handbag.fill"
        case .cultural:
            return "building.columns.fill"
        case .stadium:
            return "sportscourt.fill"
        }
    }
}

// Model for a single location on the map
struct MapLocation: Identifiable {
    let id = UUID()
    let name: String
    let type: LocationType
    let coordinate: CLLocationCoordinate2D
    let description: String
    let imageName: String
    let promotesWomenInSports: Bool
}
