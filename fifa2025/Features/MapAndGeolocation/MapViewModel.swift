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

@MainActor
class MapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var mapRegion: MKCoordinateRegion
    @Published var filteredLocations: [MapLocation] = [] // Reverted to MapLocation
    @Published var selectedLocation: MapLocation?
    @Published var locationStatus: CLAuthorizationStatus
    
    @Published var activeFilters: Set<LocationType> = Set(LocationType.allCases)
    @Published var showWomenInSportsOnly = false
    
    // UI State
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Services and Location Properties
    private let denueService = DENUEService()
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var allLocations: [MapLocation] = []

    // MARK: - Initializer
    init() {
        let defaultCenter = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        self.mapRegion = MKCoordinateRegion(center: defaultCenter, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.locationStatus = locationManager.authorizationStatus
        
        setupMapRegionDebouncing()
        fetchDataForCurrentStatus()
        
        locationManager.$authorizationStatus
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.locationStatus = status
                self?.fetchDataForCurrentStatus()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Dynamic Data Fetching
    private func setupMapRegionDebouncing() {
        $mapRegion
            .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] newRegion in
                self?.loadBusinessesFor(region: newRegion)
            }
            .store(in: &cancellables)
    }
    
    private func loadBusinessesFor(region: MKCoordinateRegion) {
        isLoading = true
        Task {
            let edgeLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude + region.span.longitudeDelta / 2)
            let centerLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            let radiusInMeters = Int(edgeLocation.distance(from: centerLocation))

            await loadBusinesses(near: region.center, radius: radiusInMeters)
            isLoading = false
        }
    }
    
    // MARK: - Core Logic with Capping
    private func loadBusinesses(near coordinate: CLLocationCoordinate2D, radius: Int) async {
        errorMessage = nil
        do {
            let businesses = try await denueService.fetchBusinesses(near: coordinate, radiusInMeters: radius)
            // ---- CAPPING LOGIC IS APPLIED HERE ----
            self.allLocations = capBusinesses(businesses, for: self.mapRegion)
            self.applyFilters()
        } catch {
            self.errorMessage = "Could not load local businesses. Please check your connection."
            print("Error fetching businesses: \(error)")
        }
    }
    
    // This new function limits the results based on zoom level
    private func capBusinesses(_ businesses: [MapLocation], for region: MKCoordinateRegion) -> [MapLocation] {
        let zoomLevel = region.span.latitudeDelta
        let limit: Int
        
        if zoomLevel > 0.2 {       // Very zoomed out
            limit = 50
        } else if zoomLevel > 0.05 { // Medium zoom
            limit = 100
        } else {                     // Zoomed in
            limit = 220
        }
        
        if businesses.count > limit {
            print("Original count: \(businesses.count), capped to: \(limit)")
            return Array(businesses.prefix(limit))
        } else {
            return businesses
        }
    }
    
    // MARK: - Core Logic
    func fetchDataForCurrentStatus() {
        isLoading = true
        Task {
            if locationManager.isAuthorized(), let location = await userLocation() {
                self.mapRegion.center = location.coordinate
                // The debouncer will automatically trigger the first load
            } else {
                // Load default data if no permission
                await loadDataForDefaultLocation()
            }
            isLoading = false
        }
    }
    
    private func loadDataForDefaultLocation() async {
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        self.mapRegion.center = defaultCoordinate
    }

    private func userLocation() async -> CLLocation? {
        let locationsSequence = locationManager.$location.compactMap { $0 }.values
        return await locationsSequence.first(where: { _ in true })
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
        
        if !activeFilters.isEmpty {
            tempLocations = tempLocations.filter { activeFilters.contains($0.type) }
        }
        
        if showWomenInSportsOnly {
            tempLocations = tempLocations.filter { $0.promotesWomenInSports }
        }
        
        self.filteredLocations = tempLocations
    }
}
