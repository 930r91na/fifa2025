//
//  User.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//
import Foundation

import SwiftUI
import Combine

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
    var isCompleted: Bool
    let description: String
    let detailedDescription: String
    let pointsAwarded: Int
    var completionDate: Date?
    var photoEvidence: UIImage?
    var review: String?
}




// MARK: - Models
struct PostModel: Identifiable {
    let id: UUID
    let user: UserModel
    let businessName: String
    let businessImageName: String
    let text: String
    var likes: Int
    var isLiked: Bool = false
    var comments: [CommentModel]
    let date: Date
    var challengePhoto: UIImage?
}

struct UserModel: Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarName: String
    let country: String
}

struct CommentModel: Identifiable {
    let id: UUID
    let user: UserModel
    let text: String
    let date: Date
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    let country: String
    let points: Int
    let flagEmoji: String
}


final class CommunityViewModel: ObservableObject {
    @Published var posts: [PostModel] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    
    private let currentUser = UserModel(
        id: UUID(),
        username: "oscar192010",
        displayName: "Oscar",
        avatarName: "user_local",
        country: "Mexico"
    )
    
    init() {
        loadSampleLeaderboard()
        loadSampleUsersAndPosts()
    }
    
    // MARK: - Load simulated leaderboard
    private func loadSampleLeaderboard() {
        leaderboard = [
            LeaderboardEntry(country: "Mexico", points: 90, flagEmoji: "🇲🇽"),
            LeaderboardEntry(country: "Argentina", points: 10, flagEmoji: "🇦🇷"),
            LeaderboardEntry(country: "Colombia", points: 45, flagEmoji: "🇨🇴"),
            LeaderboardEntry(country: "Chile", points: 30, flagEmoji: "🇨🇱"),
            LeaderboardEntry(country: "Peru", points: 25, flagEmoji: "🇵🇪"),
            LeaderboardEntry(country: "Spain", points: 60, flagEmoji: "🇪🇸")
        ].sorted { $0.points > $1.points }
    }
    
    // MARK: - Load simulated posts
    private func loadSampleUsersAndPosts() {
        let u1 = UserModel(id: UUID(), username: "maria89", displayName: "María H.", avatarName: "user1", country: "Mexico")
        let u2 = UserModel(id: UUID(), username: "carlos_rs", displayName: "Carlos R.", avatarName: "user2", country: "Argentina")
        let u3 = UserModel(id: UUID(), username: "ana_code", displayName: "Ana C.", avatarName: "user3", country: "Mexico")
        
        posts = [
            PostModel(
                id: UUID(),
                user: u1,
                businessName: "Café La Esquina",
                businessImageName: "cafe1",
                text: "Great coffee and cozy atmosphere ☕️🇲🇽",
                likes: 12,
                comments: [
                    CommentModel(id: UUID(), user: u2, text: "Thanks for the tip!", date: Date())
                ],
                date: Date().addingTimeInterval(-3600)
            ),
        ]
    }
    
    // MARK: - Add Challenge Post
    func addChallengePost(challengeTitle: String, photo: UIImage, review: String) {
        let newPost = PostModel(
            id: UUID(),
            user: currentUser,
            businessName: challengeTitle,
            businessImageName: "challenge_photo", // Aquí usarías la foto real
            text: review,
            likes: 0,
            comments: [],
            date: Date(),
            challengePhoto: photo
        )
        
        posts.insert(newPost, at: 0)
    }
    
    func toggleLike(postId: UUID) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked.toggle()
            posts[index].likes += posts[index].isLiked ? 1 : -1
        }
    }
    
    func addComment(postId: UUID, commentText: String, from user: UserModel) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let comment = CommentModel(id: UUID(), user: user, text: commentText, date: Date())
            posts[index].comments.append(comment)
        }
    }
}


