//
//  UserDataManager.swift
//  fifa2025
//
//  Created by Georgina on 12/10/25.
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
            saveUser() // 🆕 Guardar usuario completo cuando cambie
        }
    }
    
    // Keys para UserDefaults
    private let userKey = "savedUser" // 🆕 NUEVO: Guardar usuario completo
    private let pointsKey = "userPoints"
    private let streakKey = "userStreak"
    private let teamKey = "userTeam"
    private let archetypeKey = "userArchetype" // 🆕 NUEVO
    private let postsKey = "savedChallengePosts"
    
    init() {
        print("UserDataManager init()")
        
        // 1. Inicializa user con un valor por defecto (obligatorio)
        self.user = MockData.user  // ← ¡PRIMERO!
        
        // 2. AHORA sí puedes usar self.loadUser()
        if let loadedUser = loadUser() {
            self.user = loadedUser
            print("Usuario completo cargado desde UserDefaults")
            print("   - Arquetipo: \(loadedUser.archetype?.displayName ?? "None")")
        } else {
            // Fallback: cargar valores individuales
            let savedPoints = UserDefaults.standard.integer(forKey: pointsKey)
            let savedStreak = UserDefaults.standard.integer(forKey: streakKey)
            let savedTeam = UserDefaults.standard.string(forKey: teamKey)
            let savedArchetypeRaw = UserDefaults.standard.string(forKey: archetypeKey)
            
            if savedPoints > 0 { self.user.points = savedPoints }
            if savedStreak > 0 { self.user.streak = savedStreak }
            if let team = savedTeam { self.user.teamPreference = team }
            if let raw = savedArchetypeRaw,
               let archetype = UserArchetype(rawValue: raw) {
                self.user.archetype = archetype
            }
        }
        
        let savedPostsCount = loadChallengePosts().count
        print("Posts guardados: \(savedPostsCount)")
    }
    
    // MARK: - 🆕 Guardar/Cargar Usuario Completo
    
    private func saveUser() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            UserDefaults.standard.set(data, forKey: userKey)
            
            // También guardar valores individuales para compatibilidad
            UserDefaults.standard.set(user.points, forKey: pointsKey)
            UserDefaults.standard.set(user.streak, forKey: streakKey)
            UserDefaults.standard.set(user.teamPreference, forKey: teamKey)
            UserDefaults.standard.set(user.archetype?.rawValue, forKey: archetypeKey)
            
            print("💾 Usuario guardado completamente")
        } catch {
            print("❌ Error al guardar usuario: \(error)")
            // Fallback: guardar solo lo básico
            saveBasicStats()
        }
    }
    
    private func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else {
            print("⚠️ No hay usuario guardado en key: \(userKey)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: data)
            print("✅ Usuario decodificado correctamente")
            return user
        } catch {
            print("❌ Error al decodificar usuario: \(error)")
            return nil
        }
    }
    
    // MARK: - Guardar solo lo básico (fallback)
    private func saveBasicStats() {
        UserDefaults.standard.set(user.points, forKey: pointsKey)
        UserDefaults.standard.set(user.streak, forKey: streakKey)
        UserDefaults.standard.set(user.teamPreference, forKey: teamKey)
        UserDefaults.standard.set(user.archetype?.rawValue, forKey: archetypeKey)
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

        var savedPosts = loadChallengePosts()
        print("📂 Posts existentes antes de guardar: \(savedPosts.count)")
        
        savedPosts.insert(newPost, at: 0)
        print("📂 Posts después de agregar nuevo: \(savedPosts.count)")

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedPosts)
            UserDefaults.standard.set(data, forKey: postsKey)
            UserDefaults.standard.synchronize()
            
            print("💾 Post guardado exitosamente")
            
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
    
    // MARK: - 🆕 ACTUALIZADO: Complete Onboarding con Arquetipo
    func completeOnboarding(
        team: String?,
        archetype: UserArchetype?, // 🆕 NUEVO parámetro
        interests: Set<LocationType>
    ) {
        user.teamPreference = team ?? "Explorer"
        user.archetype = archetype // 🆕 Guardar arquetipo
        user.opinionOnboardingPlace = interests
        
        print("✅ Onboarding completado")
        print("   Team: \(team ?? "None")")
        print("   Archetype: \(archetype?.displayName ?? "None")")
        print("   Interests: \(interests.map { String(describing: $0) })")
    }
    
    // MARK: - Métodos existentes (sin cambios)
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
        print("📍 Visita agregada: \(visit.location.name) - Rating: \(visit.rating)")
    }
    
    func resetUser() {
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: pointsKey)
        UserDefaults.standard.removeObject(forKey: streakKey)
        UserDefaults.standard.removeObject(forKey: teamKey)
        UserDefaults.standard.removeObject(forKey: archetypeKey)
        UserDefaults.standard.removeObject(forKey: postsKey)
        self.user = MockData.user
        print("🗑️ Datos reseteados")
    }
}
