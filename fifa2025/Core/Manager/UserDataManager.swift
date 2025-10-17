//
//  UserDataManager.swift
//  fifa2025
//
//  Created by Georgina on 12/10/25.
//

//
//  UserDataManager.swift
//  fifa2025
//

import Foundation
import Combine
import UIKit

// MARK: - Modelo ligero para guardar posts
struct SavedChallengePost: Codable {
    let id: String
    let challengeTitle: String
    let review: String
    let rating: Int
    let recommended: Bool
    let photoData: Data
    let date: Date
}

@MainActor
class UserDataManager: ObservableObject {
    
    @Published var user: User {
        didSet {
            saveBasicStats()
        }
    }
    
    private let pointsKey = "userPoints"
    private let streakKey = "userStreak"
    private let teamKey = "userTeam"
    private let postsKey = "savedChallengePosts"
    
    init() {
        print("🔵 UserDataManager init()")
        
        // Cargar datos guardados
        let savedPoints = UserDefaults.standard.integer(forKey: pointsKey)
        let savedStreak = UserDefaults.standard.integer(forKey: streakKey)
        let savedTeam = UserDefaults.standard.string(forKey: teamKey)
        
        var loadedUser = MockData.user
        
        if savedPoints > 0 {
            loadedUser.points = savedPoints
            print("✅ Puntos cargados: \(savedPoints)")
        }
        if savedStreak > 0 {
            loadedUser.streak = savedStreak
            print("✅ Racha cargada: \(savedStreak)")
        }
        if let team = savedTeam {
            loadedUser.teamPreference = team
            print("✅ Equipo cargado: \(team)")
        }
        
        self.user = loadedUser
        
        // 🔍 DEBUG: Ver cuántos posts hay guardados
        let savedPostsCount = loadChallengePosts().count
        print("📂 Posts guardados en UserDefaults: \(savedPostsCount)")
    }
    
    // MARK: - Guardar solo lo básico
    private func saveBasicStats() {
        UserDefaults.standard.set(user.points, forKey: pointsKey)
        UserDefaults.standard.set(user.streak, forKey: streakKey)
        UserDefaults.standard.set(user.teamPreference, forKey: teamKey)
    }
    
    // MARK: - Guardar post de desafío
    func saveChallengePost(
        challengeTitle: String,
        photo: UIImage,
        review: String,
        rating: Int,
        recommended: Bool
    ) {
        print("🔵 saveChallengePost() llamado")
        
        guard let photoData = photo.jpegData(compressionQuality: 0.7) else {
            print("❌ Error al convertir imagen")
            return
        }
        
        let newPost = SavedChallengePost(
            id: UUID().uuidString,
            challengeTitle: challengeTitle,
            review: review,
            rating: rating,
            recommended: recommended,
            photoData: photoData,
            date: Date()
        )
        
        // Cargar posts existentes
        var savedPosts = loadChallengePosts()
        print("📂 Posts existentes antes de guardar: \(savedPosts.count)")
        
        savedPosts.insert(newPost, at: 0)
        print("📂 Posts después de agregar nuevo: \(savedPosts.count)")
        
        // Guardar actualizado
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedPosts)
            UserDefaults.standard.set(data, forKey: postsKey)
            UserDefaults.standard.synchronize()  // ✅ Forzar guardado inmediato
            
            print("💾 Post guardado exitosamente")
            
            // 🔍 Verificar que se guardó
            let verification = loadChallengePosts()
            print("✅ Verificación: \(verification.count) posts en UserDefaults")
            
        } catch {
            print("❌ Error al guardar post: \(error)")
        }
    }
    
    // MARK: - Cargar posts guardados
    func loadChallengePosts() -> [SavedChallengePost] {
        print("🔵 loadChallengePosts() llamado")
        
        guard let data = UserDefaults.standard.data(forKey: postsKey) else {
            print("⚠️ No hay datos en UserDefaults para key: \(postsKey)")
            return []
        }
        
        print("✅ Datos encontrados en UserDefaults, tamaño: \(data.count) bytes")
        
        do {
            let decoder = JSONDecoder()
            let posts = try decoder.decode([SavedChallengePost].self, from: data)
            print("✅ \(posts.count) posts decodificados correctamente")
            
            // Debug: Mostrar títulos
            for (index, post) in posts.enumerated() {
                print("  [\(index)] \(post.challengeTitle) - \(post.date)")
            }
            
            return posts
        } catch {
            print("❌ Error al decodificar posts: \(error)")
            return []
        }
    }
    
    // MARK: - Convertir posts guardados a PostModel
    func convertToPostModels() -> [PostModel] {
        print("🔵 convertToPostModels() llamado")
        
        let savedPosts = loadChallengePosts()
        print("📂 Posts a convertir: \(savedPosts.count)")
        
        let currentUser = UserModel(
            id: UUID(),
            username: "oscar192010",
            displayName: "Oscar",
            avatarName: "user_local",
            country: "Mexico"
        )
        
        let converted = savedPosts.compactMap { saved -> PostModel? in
            guard let photo = UIImage(data: saved.photoData) else {
                print("⚠️ No se pudo convertir imagen para: \(saved.challengeTitle)")
                return nil
            }
            
            return PostModel(
                id: UUID(),
                user: currentUser,
                businessName: saved.challengeTitle,
                businessImageName: "challenge_photo",
                text: saved.review,
                likes: 0,
                comments: [],
                date: saved.date,
                challengePhoto: photo,
                rating: saved.rating,
                recommended: saved.recommended
            )
        }
        
        print("✅ \(converted.count) posts convertidos a PostModel")
        return converted
    }
    
    // MARK: - Métodos existentes
    func completeOnboarding(team: String?, interests: Set<LocationType>) {
        user.teamPreference = team ?? "Explorer"
        user.opinionOnboardingPlace = interests
        print("✅ Onboarding completado")
    }
    
    func addPoints(_ points: Int) {
        user.points += points
        print("➕ \(points) puntos. Total: \(user.points)")
    }
    
    func incrementStreak() {
        user.streak += 1
        print("🔥 Racha: \(user.streak) días")
    }
    
    func addCompletedChallenge(_ challenge: Challenge) {
        var updated = challenge
        updated.isCompleted = true
        updated.completionDate = Date()
        user.completedChallenges.append(updated)
    }
    
    func addVisit(_ visit: Visit) {
        user.visits.append(visit)
    }
    
    // Resetear todo
    func resetUser() {
        UserDefaults.standard.removeObject(forKey: pointsKey)
        UserDefaults.standard.removeObject(forKey: streakKey)
        UserDefaults.standard.removeObject(forKey: teamKey)
        UserDefaults.standard.removeObject(forKey: postsKey)
        self.user = MockData.user
        print("🗑️ Datos reseteados")
    }
}
