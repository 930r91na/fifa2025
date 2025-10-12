//
//  MapLocation.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation
import SwiftUI

// Enum for filtering categories
enum LocationType: Int, CaseIterable, Identifiable {
    case food = 0
    case shop = 1
    case cultural = 2
    case stadium = 3
    case others = 4
    
    var id: Int { rawValue }
    
    var type: LocalizedStringKey{
        switch self {
        case .food:
            return "Food"
        case .shop:
            return "Shop"
        case .cultural:
            return "Cultural"
        case .stadium:
            return "Stadium"
        case .others:
            return "Others"
        }
    }
    
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
        case .others:
            return "scope"
        }
    }
}

// Model for a single location on the map
struct MapLocation: Identifiable {
    let id: UUID
    let name: String
    let type: LocationType
    let coordinate: CLLocationCoordinate2D
    let description: String
    let imageName: String
    let promotesWomenInSports: Bool
    
    let address: String?
    let phoneNumber: String?
    let website: String?

    init(id: UUID = UUID(), name: String, type: LocationType, coordinate: CLLocationCoordinate2D, description: String, imageName: String, promotesWomenInSports: Bool, address: String? = nil, phoneNumber: String? = nil, website: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.coordinate = coordinate
        self.description = description
        self.imageName = imageName
        self.promotesWomenInSports = promotesWomenInSports
        self.address = address
        self.phoneNumber = phoneNumber
        self.website = website
    }
}
