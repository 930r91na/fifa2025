//
//  MapLocation.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

enum LocationType: Int, CaseIterable, Identifiable {
    case food = 0
    case shop = 1
    case cultural = 2
    case stadium = 3
    case entertainment = 4
    case souvenirs = 5
    case others = 6
    
    var id: Int { rawValue }
    
    var type: LocalizedStringKey {
        switch self {
        case .food:
            return "Comida"
        case .shop:
            return "Tienda"
        case .cultural:
            return "Cultural"
        case .stadium:
            return "Estadio"
        case .entertainment:
            return "Entretenimiento"
        case .souvenirs:
            return "Souvenirs"
        case .others:
            return "Otros"
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
        case .entertainment:
            return "music.mic"
        case .souvenirs:
            return "gift.fill"
        case .others:
            return "ellipsis.circle.fill"
        }
    }
}

struct MapLocation: Identifiable, Equatable {
    let id: UUID
    let denueID: String?
    let name: String
    let type: LocationType
    let coordinate: CLLocationCoordinate2D
    let description: String
    let imageName: String
    let promotesWomenInSports: Bool
    
    let address: String?
    let phoneNumber: String?
    let website: String?

    init(id: UUID = UUID(), denueID: String, name: String, type: LocationType, coordinate: CLLocationCoordinate2D, description: String, imageName: String, promotesWomenInSports: Bool, address: String? = nil, phoneNumber: String? = nil, website: String? = nil) {
        self.id = id
        self.denueID = denueID
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
    
   
    static func == (lhs: MapLocation, rhs: MapLocation) -> Bool {
        return lhs.denueID == rhs.denueID
    }
}

final class MapAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    let locationType: LocationType

    init(location: MapLocation) {
        self.title = location.name
        self.coordinate = location.coordinate
        self.locationType = location.type
    }
}
