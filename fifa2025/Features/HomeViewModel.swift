//
//  HomeViewModel.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation
import Combine
internal import EventKit

@MainActor
class HomeViewModel: ObservableObject {
    @Published var suggestions: [ItinerarySuggestion] = []
    @Published var calendarAuthorizationStatus: EKAuthorizationStatus
    
    private let calendarManager = CalendarManager()
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.calendarAuthorizationStatus = calendarManager.authorizationStatus
        
        // When calendar events or user location update, regenerate suggestions
        Publishers.CombineLatest(calendarManager.$events, locationManager.$location.compactMap { $0 })
            .debounce(for: .seconds(1), scheduler: RunLoop.main) // Avoid rapid updates
            .sink { [weak self] (events, userLocation) in
                self?.regenerateSuggestions(events: events, userLocation: userLocation)
            }
            .store(in: &cancellables)
        
        // Update local auth status when manager's status changes
        calendarManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$calendarAuthorizationStatus)
    }
    
    func requestCalendarAccess() {
        calendarManager.requestAccess()
    }
    
    private func regenerateSuggestions(events: [Event], userLocation: CLLocation) {
        let now = Date()
        let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60 - 1)
        
        let freeSlots = SuggestionEngine.findFreeTimeSlots(events: events, from: now, to: endOfDay)
        self.suggestions = SuggestionEngine.generateSuggestions(
            for: freeSlots,
            from: userLocation,
            to: MockData.locations
        )
    }
}
