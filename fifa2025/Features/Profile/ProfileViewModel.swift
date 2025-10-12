//
//  ProfileViewModel.swift
//  fifa2025
//
//  Created by Georgina on 11/10/25.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    init() {
        self.user = MockData.user
    }
    
    func fetchUserData() {
        // In a real implementation, this would make an API call
        // and update the user property.
        self.user = MockData.user
    }
}
