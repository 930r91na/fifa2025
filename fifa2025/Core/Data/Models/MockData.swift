//
//  MockData.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation

struct MockData {
    static let locations: [MapLocation] = [
        MapLocation(
            name: "Estadio Azteca",
            type: .stadium,
            coordinate: CLLocationCoordinate2D(latitude: 19.3028, longitude: -99.1504),
            description: "Iconic stadium, host of the 1970 and 1986 World Cup finals. Also hosted the final of the 1971 Women's World Cup.",
            imageName: "estadio_azteca",
            promotesWomenInSports: true
        ),
        MapLocation(
            name: "Tacos Chupacabras",
            type: .food,
            coordinate: CLLocationCoordinate2D(latitude: 19.3305, longitude: -99.1601),
            description: "Famous local taco spot known for its unique flavors. A must-visit for authentic street food.",
            imageName: "tacos_chupacabras",
            promotesWomenInSports: false
        ),
        MapLocation(
            name: "Mercado de Coyoacán",
            type: .shop,
            coordinate: CLLocationCoordinate2D(latitude: 19.3496, longitude: -99.1618),
            description: "Vibrant market with local crafts, food, and souvenirs. Experience the local culture and flavors.",
            imageName: "mercado_coyoacan",
            promotesWomenInSports: false
        ),
        MapLocation(
            name: "Museo Frida Kahlo",
            type: .cultural,
            coordinate: CLLocationCoordinate2D(latitude: 19.3551, longitude: -99.1623),
            description: "The 'Blue House' where the famous Mexican artist Frida Kahlo lived and worked.",
            imageName: "museo_frida",
            promotesWomenInSports: true
        )
    ]
}
