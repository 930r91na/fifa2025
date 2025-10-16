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
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var suggestions: [ItinerarySuggestion] = []
    @Published var calendarAuthorizationStatus: EKAuthorizationStatus
    @Published var showScheduleAlert = false
    @Published var scheduleAlertMessage = ""
    @StateObject private var userDataManager = UserDataManager()
    
    private let calendarManager = CalendarManager()
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Debugging Flag
    private let useMockLocation = true
    
    init() {
        self.calendarAuthorizationStatus = calendarManager.authorizationStatus
        
        calendarManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$calendarAuthorizationStatus)

        if useMockLocation {
            locationManager.startUpdatingLocationWithMock()
        } else {
            locationManager.startUpdatesIfNeeded()
        }
    }
    
    func loadInitialData() async {
        Publishers.CombineLatest(calendarManager.$events, locationManager.$location.compactMap { $0 })
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] (events, userLocation) in
                self?.regenerateSuggestions(events: events, userLocation: userLocation)
            }
            .store(in: &cancellables)
    }
    
    func checkAndRequestPermissionsIfNeeded() {
        if calendarAuthorizationStatus == .notDetermined {
            calendarManager.requestAccess()
        } else if calendarAuthorizationStatus == .fullAccess {
            calendarManager.fetchEvents()
        }
    }
    
    func requestCalendarAccess() {
        calendarManager.requestAccess()
    }
    
    func scheduleSuggestion(_ suggestion: ItinerarySuggestion) {
        calendarManager.addEvent(suggestion: suggestion) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.scheduleAlertMessage = "\(suggestion.location.name) has been added to your calendar!"
                } else {
                    self?.scheduleAlertMessage = "Failed to add event. Please check your calendar permissions in Settings."
                }
                self?.showScheduleAlert = true
            }
        }
    }
    
    private func regenerateSuggestions(events: [Event], userLocation: CLLocation) {
            let now = Date()
            let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60 - 1)
            
            let freeSlots = SuggestionEngine.findFreeTimeSlots(events: events, from: now, to: endOfDay)
            
            self.suggestions = SuggestionEngine.generateSuggestions(
                for: freeSlots,
                from: userLocation,
                for: userDataManager.user,
                allLocations: MockData.locations
            )
        }
}
