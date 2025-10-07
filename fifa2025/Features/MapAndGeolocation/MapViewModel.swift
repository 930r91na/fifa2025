//
//  MapViewModel.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import MapKit
import Combine
import SwiftUI

class MapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var mapRegion: MKCoordinateRegion
    @Published var allLocations: [MapLocation] = MockData.locations
    @Published var filteredLocations: [MapLocation] = []
    @Published var selectedLocation: MapLocation?
    
    @Published var activeFilters: Set<LocationType> = Set(LocationType.allCases)
    @Published var showWomenInSportsOnly = false
    
    // MARK: - Location Properties
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var didCenterOnUser = false

    // MARK: - Initializer
    init() {
        // Default region (will be updated to user's location)
        self.mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        self.filteredLocations = allLocations
        
        // Subscribe to location updates
        locationManager.$location
            .compactMap { $0 }
            .first() // Only take the first valid location to center the map
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.centerOnUserLocation(location.coordinate)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    func centerOnUserLocation(_ coordinate: CLLocationCoordinate2D? = nil) {
        let coordinateToCenter = coordinate ?? locationManager.location?.coordinate
        
        guard let center = coordinateToCenter else {
            print("User location not available to center map.")
            return
        }
        
        withAnimation(.easeIn) {
            mapRegion = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    func toggleFilter(_ filter: LocationType) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
        applyFilters()
    }
    
    func toggleWomenInSportsFilter() {
        showWomenInSportsOnly.toggle()
        applyFilters()
    }
    
    private func applyFilters() {
        var tempLocations = allLocations
        
        // Category filters
        tempLocations = tempLocations.filter { location in
            activeFilters.contains(location.type)
        }
        
        // Women in sports filter
        if showWomenInSportsOnly {
            tempLocations = tempLocations.filter { $0.promotesWomenInSports }
        }
        
        withAnimation {
            filteredLocations = tempLocations
        }
    }
}
