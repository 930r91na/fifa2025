//
//  fifa2025App.swift
//  fifa2025
//
//  Created by Georgina on 30/09/25.
//

import SwiftUI

@main
struct fifa2025App: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @StateObject private var userDataManager = UserDataManager()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
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
        // 1. Check if it's our custom card file
        guard url.pathExtension == "worldcupcard" else {
            return
        }
    
        // 2. Read the file's data
        do {
            let data = try Data(contentsOf: url)
            
            // 3. Decode the data back into our card object
            let receivedCard = try JSONDecoder().decode(WorldCupCard.self, from: data)
            
            print("Successfully received card: \(receivedCard.title)!")
            
            // 4. TODO: Add the card to the user's collection
            // We will handle this in the next step, for now we just print it.
                
            // Optional: Clean up the file from the app's inbox
            try? FileManager.default.removeItem(at: url)
                
        } catch {
            print("Failed to decode incoming card: \(error)")
        }
    }
}
