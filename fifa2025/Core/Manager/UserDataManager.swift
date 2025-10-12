//
//  UserDataManager.swift
//  fifa2025
//
//  Created by Georgina on 12/10/25.
//

import Foundation
import Combine

// This class will manage the current user's data.
@MainActor
class UserDataManager: ObservableObject {
    
    @Published var user: User
    
    init() {
        self.user = MockData.user
    }
    
    func completeOnboarding(team: String?, interests: Set<LocationType>) {
        user.teamPreference = team ?? "Explorer"
        user.opinionOnboardingPlace = interests
        
        // Here you would save the user object to device storage.
        print("Onboarding complete! User supports \(user.teamPreference) and is interested in \(user.opinionOnboardingPlace).")
    }
}
