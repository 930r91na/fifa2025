//
//  MapViewModel.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import MapKit
import SwiftUI
import Combine

@MainActor
final class MapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var filteredLocations: [MapLocation] = []
    @Published var mapRegion: MKCoordinateRegion
    @Published var errorMessage: String?
    @Published var showAlert: Bool = false
    @Published var isLoading: Bool = false
    @Published var selectedFilters: Set<LocationType> = Set(LocationType.allCases)
    
    // MARK: - Private Properties
    private let denueService = DENUEService()
    private var cancellables = Set<AnyCancellable>()
    
    // Caching Layers
    private var locationCache = CacheManager<[MapLocation]>() // Cache for final MapLocation objects
    private var fetchedGridKeys = Set<String>() // Tracks which grid cells have been fetched
    
    // Grid Logic
    private let gridCellSizeInMeters: CLLocationDistance = 2500 // 2.5km grid cells

    init() {
        self.mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Debounce map region changes
        $mapRegion
            .debounce(for: .milliseconds(750), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.updateVisibleGridAndFetchData() }
            .store(in: &cancellables)
        
        // React to filter changes by re-applying them to the already fetched data
        $selectedFilters
            .sink { [weak self] _ in self?.applyFilters() }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading and Orchestration
    
    func loadInitialData() async {
        self.filteredLocations = MockData.locations // Start with mock data for immediate UI
        await updateVisibleGridAndFetchData()
    }
    
    private func updateVisibleGridAndFetchData() {
        let centerKey = gridKey(for: mapRegion.center)
        
        guard !fetchedGridKeys.contains(centerKey) else { return }
        
        Task {
            isLoading = true
            fetchedGridKeys.insert(centerKey) // Mark as fetched immediately
            
            // Fetch for each category sequentially to avoid overloading the API
            for category in Array(selectedFilters) {
                await loadBusinesses(for: category, gridKey: centerKey, near: mapRegion.center, radius: Int(gridCellSizeInMeters))
            }
            
            isLoading = false
        }
    }

    private func loadBusinesses(for category: LocationType, gridKey: String, near coordinate: CLLocationCoordinate2D, radius: Int) async {
        let cacheKey = "\(gridKey)-\(category.rawValue)"
        
        // Check our ViewModel's cache first
        if let cachedLocations = locationCache.getValue(forKey: cacheKey) {
            addLocationsToMap(cachedLocations)
            return
        }

        // If not, fetch from the service
        do {
            let businesses = try await denueService.fetchBusinesses(for: category, gridKey: gridKey, near: coordinate, radiusInMeters: radius)
            locationCache.setValue(businesses, forKey: cacheKey) // Cache the result
            addLocationsToMap(businesses)
        } catch {
            self.errorMessage = "Could not load some local businesses. Please check your connection."
            self.showAlert = true
            print("Error fetching category \(category): \(error)")
        }
    }
    
    // MARK: - Filtering and State Management
    
    private func addLocationsToMap(_ newLocations: [MapLocation]) {
        // Add only new, unique businesses to our main list
        let existingIDs = Set(self.filteredLocations.map { $0.denueID })
        let uniqueNewLocations = newLocations.filter { !existingIDs.contains($0.denueID) }
        
        self.filteredLocations.append(contentsOf: uniqueNewLocations)
    }
    
    func applyFilters() {
        // Instead of re-fetching, we'll re-filter our cached data.
        // This is a more advanced step. For now, we'll just handle adding/removing.
        // The current logic in `loadBusinesses` already fetches based on `selectedFilters`.
        // A full re-filter would involve iterating over `fetchedGridKeys` and their cached data.
    }
    
    func toggleFilter(for type: LocationType) {
        if selectedFilters.contains(type) {
            selectedFilters.remove(type)
            // Remove locations of this type from the map
            filteredLocations.removeAll { $0.type == type }
        } else {
            selectedFilters.insert(type)
            // Trigger a fetch for this new category in the current grid
            updateVisibleGridAndFetchData()
        }
    }
    
    /// Generates a unique key for a grid cell.
    private func gridKey(for coordinate: CLLocationCoordinate2D) -> String {
        let latIndex = Int(coordinate.latitude * 100)
        let lonIndex = Int(coordinate.longitude * 100)
        return "\(latIndex)-\(lonIndex)"
    }
}
