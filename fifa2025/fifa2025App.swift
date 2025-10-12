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

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .foregroundColor(Color("BackgroudColor"))
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}
