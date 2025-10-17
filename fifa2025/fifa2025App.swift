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
    @StateObject private var communityVM = CommunityViewModel()
    
    @State private var receivedCard: WorldCupCard?
    @State private var showSplash = true  // ← Control del splash

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(
                        receivedCard: $receivedCard,
                        userDataManager: userDataManager,
                        communityVM: communityVM
                    )
                    .transition(.opacity)
                } else {
                    if hasCompletedOnboarding {
                        ContentView(
                            receivedCard: $receivedCard,
                            userDataManager: userDataManager,
                            communityVM: communityVM
                        )
                        .foregroundColor(Color("BackgroundColor"))
                        .onOpenURL { url in
                            handleIncomingCard(from: url)
                        }
                        .environmentObject(userDataManager)
                        .environmentObject(communityVM)
                    } else {
                        OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                            .environmentObject(userDataManager)
                    }
                }
            }
            .onAppear {
                communityVM.connectUserData(userDataManager)
                
                // Ocultar splash después de 2.5 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
    
    private func handleIncomingCard(from url: URL) {
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
                let data = try Data(contentsOf: url)
                let card = try JSONDecoder().decode(WorldCupCard.self, from: data)
                
                print("Successfully received card: \(card.title)!")
                self.receivedCard = card
                
                try? FileManager.default.removeItem(at: url)
                
            } else {
                print("Received file is not a WorldCupCard.")
            }
        } catch {
            print("Failed to handle incoming card: \(error)")
        }
    }
}
