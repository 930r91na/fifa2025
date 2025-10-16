//
//  fifa2025App.swift
//  fifa2025
//
//  Created by Georgina on 30/09/25.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct fifa2025App: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @StateObject private var userDataManager = UserDataManager()
    
    @State private var receivedCard: WorldCupCard?

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView(receivedCard: $receivedCard)
                    .foregroundColor(Color("BackgroudColor"))
                    .onOpenURL { url in
                        handleIncomingCard(from: url)
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(userDataManager)
            }
        }
    }
    
    
    private func handleIncomingCard(from url: URL) {
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource.")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
                
                if let contentType = resourceValues.contentType, contentType.conforms(to: .worldCupCard) {
                    
                    // Read the file's data
                    let data = try Data(contentsOf: url)
                    
                    // Decode the data back into our card object
                    let card = try JSONDecoder().decode(WorldCupCard.self, from: data)
                    
                    print("Successfully received card: \(card.title)!")
                    
                    // Set the receivedCard state to trigger the pop-up view
                    self.receivedCard = card
                    
                    // Optional: Clean up the file from the app's inbox
                    try? FileManager.default.removeItem(at: url)
                    
                } else {
                    print("Received file is not a WorldCupCard.")
                }
            } catch {
                print("Failed to handle incoming card: \(error)")
            }
        }
}
