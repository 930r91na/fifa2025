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
            denueID: "",
            name: "Estadio Azteca",
            type: .stadium,
            coordinate: CLLocationCoordinate2D(latitude: 19.3028, longitude: -99.1504),
            description: "Iconic stadium, host of the 1970 and 1986 World Cup finals. Also hosted the final of the 1971 Women's World Cup.",
            imageName: "estadio_azteca",
            promotesWomenInSports: true
            
        ),
        MapLocation(
            denueID: "",
            name: "Tacos Chupacabras",
            type: .food,
            coordinate: CLLocationCoordinate2D(latitude: 19.3305, longitude: -99.1601),
            description: "Famous local taco spot known for its unique flavors. A must-visit for authentic street food.",
            imageName: "tacos_chupacabras",
            promotesWomenInSports: false
        ),
        MapLocation(
            denueID: "",
            name: "Mercado de Coyoacán",
            type: .shop,
            coordinate: CLLocationCoordinate2D(latitude: 19.3496, longitude: -99.1618),
            description: "Vibrant market with local crafts, food, and souvenirs. Experience the local culture and flavors.",
            imageName: "mercado_coyoacan",
            promotesWomenInSports: false
        ),
        MapLocation(
            denueID: "",
            name: "Museo Frida Kahlo",
            type: .cultural,
            coordinate: CLLocationCoordinate2D(latitude: 19.3551, longitude: -99.1623),
            description: "The 'Blue House' where the famous Mexican artist Frida Kahlo lived and worked.",
            imageName: "museo_frida",
            promotesWomenInSports: true
        )
    ]
    
    static func randomMockImage() -> String {
        let imageNames = ["estadio_azteca", "tacos_chupacabras", "mercado_coyoacan", "museo_frida"]
        return imageNames.randomElement() ?? "mercado_coyoacan"
    }
    
    static let user = User(
        id: UUID(),
        name: "Óscar",
        profileImageName: "person.crop.circle",
        teamPreference: "Mexico",
        points: 2500,
        streak: 5,
        completedChallenges: [
            Challenge(
                id: UUID(),
                title: "Local Taster",
                isCompleted: true,
                description: "Visit a local restaurant",
                detailedDescription: "Visita un restaurante local, toma una foto de evidencia y deja una reseña.",
                pointsAwarded: 50,
                completionDate: Date().addingTimeInterval(-86400 * 2)
            ),
            Challenge(
                id: UUID(),
                title: "Cultural Explorer",
                isCompleted: false,
                description: "Visit a museum",
                detailedDescription: "Explora un museo o sitio cultural y comparte tu experiencia.",
                pointsAwarded: 100,
                completionDate: Date().addingTimeInterval(-86400 * 5)
            )
        ],
            visits: [
                Visit(id: UUID(), location: locations[0], date: Date().addingTimeInterval(-86400), rating: 5, comment: "An absolutely iconic and historic venue! The energy is palpable."),
                Visit(id: UUID(), location: locations[1], date: Date().addingTimeInterval(-86400 * 3), rating: 4, comment: "Delicious tacos, a truly authentic experience."),
                Visit(id: UUID(), location: locations[2], date: Date().addingTimeInterval(-86400 * 7), rating: 5, comment: "A beautiful and inspiring place. A must-see in Mexico City.")
            ], cards: nil
        )
    
    static let challengesAvailable: [Challenge] = [
            .init(
                id: UUID(),
                title: "Catador local",
                isCompleted: false,
                description: "Visit a local restaurant",
                detailedDescription: "Visita un restaurante local, toma una foto de evidencia y deja una reseña para compartir con la comunidad. ¡Tu experiencia inspirará a otros!",
                pointsAwarded: 50,
                completionDate: nil
            ),
            .init(
                id: UUID(),
                title: "Explorador cultural",
                isCompleted: false,
                description: "Visit a museum",
                detailedDescription: "Explora un museo o sitio cultural, captura el momento con una foto y comparte tu experiencia con una reseña detallada.",
                pointsAwarded: 100,
                completionDate: nil
            ),
            .init(
                id: UUID(),
                title: "Para los amantes de la comida",
                isCompleted: false,
                description: "Try a new cuisine",
                detailedDescription: "Atrévete a probar una cocina nueva, fotografía el platillo y cuéntanos qué te pareció en una reseña.",
                pointsAwarded: 150,
                completionDate: nil
            )
        ]
    
}


