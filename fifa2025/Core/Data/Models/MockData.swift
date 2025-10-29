//
//  MockData.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//



//
//  MockData.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation

struct MockData {
    
    
    // Usuario por defecto (actualizado con nuevo campo archetype)
    static let user = User(
        id: UUID(),
        name: "Oscar",
        profileImageName: "user_local",
        teamPreference: "Explorer",
        opinionOnboardingPlace: Set<LocationType>(),
        archetype: nil, // 🆕 Se configurará en onboarding
        points: 0,
        streak: 0,
        completedChallenges: [],
        visits: [],
        cards: nil
    )
    
    // Sample locations
    static let sampleLocations: [MapLocation] = [
        MapLocation(
            id: "museo_frida_001",  // ← AÑADIDO
            denueID: "museo_frida_001",
            name: "Museo Frida Kahlo",
            type: .cultural,
            coordinate: CLLocationCoordinate2D(latitude: 19.3551, longitude: -99.1620),
            description: "Casa Azul, museo dedicado a la vida y obra de Frida Kahlo",
            imageName: "museo_frida",
            promotesWomenInSports: false,
            address: "Londres 247, Del Carmen, Coyoacán",
            phoneNumber: "+52 55 5554 5999",
            website: "https://museofridakahlo.org.mx"
        ),
        MapLocation(
            id: "tacos_guero_001",  // ← AÑADIDO
            denueID: "tacos_guero_001",
            name: "Tacos El Güero",
            type: .food,
            coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            description: "Tacos tradicionales de la Ciudad de México",
            imageName: "tacos_guero",
            promotesWomenInSports: false,
            address: "Av. Insurgentes Sur 1235",
            phoneNumber: "+52 55 1234 5678",
            website: nil
        ),
        MapLocation(
            id: "estadio_azteca_001",  // ← AÑADIDO
            denueID: "estadio_azteca_001",
            name: "Estadio Azteca",
            type: .stadium,
            coordinate: CLLocationCoordinate2D(latitude: 19.3029, longitude: -99.1506),
            description: "Estadio icónico, sede de dos finales de Copa Mundial",
            imageName: "estadio_azteca",
            promotesWomenInSports: true,
            address: "Calz. de Tlalpan 3465, Sta. Úrsula Coapa",
            phoneNumber: "+52 55 5617 8080",
            website: "https://estadioazteca.com.mx"
        ),
        MapLocation(
            id: "mercado_artesanias_001",  // ← AÑADIDO
            denueID: "mercado_artesanias_001",
            name: "Mercado de Artesanologías",
            type: .souvenirs,
            coordinate: CLLocationCoordinate2D(latitude: 19.4270, longitude: -99.1677),
            description: "Mercado tradicional con artesanías mexicanas",
            imageName: "mercado_artesanias",
            promotesWomenInSports: false,
            address: "Londres 154, Zona Rosa",
            phoneNumber: nil,
            website: nil
        ),
        MapLocation(
            id: "bar_faena_001",  // ← AÑADIDO
            denueID: "bar_faena_001",
            name: "Bar La Faena",
            type: .entertainment,
            coordinate: CLLocationCoordinate2D(latitude: 19.4285, longitude: -99.1640),
            description: "Bar popular con ambiente vibrante",
            imageName: "bar_faena",
            promotesWomenInSports: false,
            address: "Calle Amberes 78, Juárez",
            phoneNumber: "+52 55 9876 5432",
            website: nil
        )
    ]
    
    // Sample challenges
    static let challengesAvailable: [Challenge] = [
        Challenge(
            id: UUID(),
            title: "Prueba Tacos de 3 Lugares",
            isCompleted: false,
            description: "Visita y califica tacos de tres lugares diferentes",
            detailedDescription: "Explora la escena de tacos en CDMX visitando tres taquerías locales. Toma fotos y comparte tu experiencia.",
            pointsAwarded: 50,
            completionDate: nil,
            photoEvidenceData: nil,
            review: nil,
            rating: nil,
            recommended: nil
        ),
        Challenge(
            id: UUID(),
            title: "Tour Cultural",
            isCompleted: false,
            description: "Visita 2 museos en un día",
            detailedDescription: "Sumérgete en la rica cultura de México visitando dos museos diferentes en un solo día.",
            pointsAwarded: 75,
            completionDate: nil,
            photoEvidenceData: nil,
            review: nil,
            rating: nil,
            recommended: nil
        ),
        Challenge(
            id: UUID(),
            title: "Fanático del Estadio",
            isCompleted: false,
            description: "Asiste a un partido en el Estadio Azteca",
            detailedDescription: "Vive la emoción de un partido en el legendario Estadio Azteca.",
            pointsAwarded: 100,
            completionDate: nil,
            photoEvidenceData: nil,
            review: nil,
            rating: nil,
            recommended: nil
        )
    ]
    
    // Sample visits
    static let sampleVisits: [Visit] = [
        Visit(
            id: UUID(),
            location: sampleLocations[0],
            date: Date().addingTimeInterval(-86400 * 2), // 2 días atrás
            rating: 5,
            comment: "¡Increíble experiencia cultural!"
        ),
        Visit(
            id: UUID(),
            location: sampleLocations[1],
            date: Date().addingTimeInterval(-86400 * 1), // 1 día atrás
            rating: 4,
            comment: "Los mejores tacos al pastor"
        )
    ]
}

// MARK: - Extension para crear usuario de prueba con datos
extension MockData {
    static func randomMockImage() -> String {
            let mockImages = [
                "museo_frida",
                "tacos_guero",
                "estadio_azteca",
                "mercado_artesanias",
                "bar_faena",
                "placeholder_food",
                "placeholder_shop",
                "placeholder_cultural",
                "placeholder_stadium",
                "placeholder_entertainment"
            ]
            return mockImages.randomElement() ?? "placeholder_generic"
        }
    
    static func userWithHistory() -> User {
        User(
            id: UUID(),
            name: "Oscar",
            profileImageName: "user_local",
            teamPreference: "México",
            opinionOnboardingPlace: [LocationType.food, LocationType.cultural, LocationType.stadium],
            archetype: UserArchetype.gourmetFoodie,
            points: 150,
            streak: 5,
            completedChallenges: [],
            visits: sampleVisits,
            cards: nil
        )
    }
    
    static func userNewbie() -> User {
        User(
            id: UUID(),
            name: "María",
            profileImageName: "user_local",
            teamPreference: "Argentina",
            opinionOnboardingPlace: [LocationType.cultural, LocationType.entertainment],
            archetype: UserArchetype.casualTourist,
            points: 0,
            streak: 0,
            completedChallenges: [],
            visits: [],
            cards: nil
        )
    }
}
