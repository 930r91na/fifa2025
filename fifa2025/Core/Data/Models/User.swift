//
//  User.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//
import Foundation

struct User: Identifiable {
    let id: UUID
    let name: String
    let profileImageName: String
    var teamPreference: String
    var opinionOnboardingPlace: Set<LocationType>?
    
    // Gamification Stats
    var points: Int
    var streak: Int
    var completedChallenges: [Challenge]
    
    var visits: [Visit]
    
    func recentVisits(limit: Int) -> [Visit] {
        return Array(visits.sorted(by: { $0.date > $1.date }).prefix(limit))
    }
}

struct Visit: Identifiable {
    let id: UUID
    let location: MapLocation
    let date: Date
    let rating: Int 
    let comment: String?
}

struct Challenge: Identifiable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let description: String
    let pointsAwarded: Int
    let completionDate: Date?
}
