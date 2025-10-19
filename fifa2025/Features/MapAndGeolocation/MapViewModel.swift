
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
    
    private var locationCache = CacheManager<[MapLocation]>()
    private var fetchedGridKeys = Set<String>()
    private let gridCellSizeInMeters: CLLocationDistance = 2500
    
    private actor LocationStore {
        var locations: [MapLocation] = []

        func add(newLocations: [MapLocation]) {
            let existingIDs = Set(locations.map { $0.denueID })
            let uniqueNewLocations = newLocations.filter { !existingIDs.contains($0.denueID) }
            locations.append(contentsOf: uniqueNewLocations)
        }
    }
    
    private let locationStore = LocationStore()

    init() {
        self.mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        setupBindings()
    }
    
    private func setupBindings() {
        $mapRegion
            .debounce(for: .milliseconds(750), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateVisibleGridAndFetchData()
                }
            }
            .store(in: &cancellables)
        
        $selectedFilters
            .sink { [weak self] _ in self?.applyFilters() }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading and Orchestration
    
    func loadInitialData() async {
        self.filteredLocations = MockData.locations
        await updateVisibleGridAndFetchData()
    }
    
    private func updateVisibleGridAndFetchData() {
        let centerKey = gridKey(for: mapRegion.center)
            
        guard !fetchedGridKeys.contains(centerKey) else { return }
        
        Task(priority: .userInitiated) {
            isLoading = true
            fetchedGridKeys.insert(centerKey)
                
            await withTaskGroup(of: Void.self) { group in
                for category in Array(selectedFilters) {
                    group.addTask {
                        await self.loadBusinesses(for: category, gridKey: centerKey, near: self.mapRegion.center, radius: Int(self.gridCellSizeInMeters))
                    }
                }
            }
                
            isLoading = false
        }
    }

    private func loadBusinesses(for category: LocationType, gridKey: String, near coordinate: CLLocationCoordinate2D, radius: Int) async {
        let cacheKey = "\(gridKey)-\(category.rawValue)"

        if let cachedLocations = locationCache.getValue(forKey: cacheKey) {
            await addLocationsToMap(cachedLocations)
            return
        }
        do {
            let businesses = try await denueService.fetchBusinesses(for: category, gridKey: gridKey, near: coordinate, radiusInMeters: radius)
            locationCache.setValue(businesses, forKey: cacheKey)
            await addLocationsToMap(businesses)
        } catch {
            self.errorMessage = "Could not load some local businesses. Please check your connection."
            self.showAlert = true
            print("Error fetching category \(category): \(error)")
        }
    }
    
    // MARK: - Filtering and State Management
    private func addLocationsToMap(_ newLocations: [MapLocation]) async {
        await locationStore.add(newLocations: newLocations)
        self.filteredLocations = await locationStore.locations
    }
    
    func applyFilters() {
  
    }
    
    func toggleFilter(for type: LocationType) {
        if selectedFilters.contains(type) {
            selectedFilters.remove(type)
            filteredLocations.removeAll { $0.type == type }
        } else {
            selectedFilters.insert(type)
            Task {
                await updateVisibleGridAndFetchData()
            }
        }
    }
    
    private func gridKey(for coordinate: CLLocationCoordinate2D) -> String {
        let latIndex = Int(coordinate.latitude * 100)
        let lonIndex = Int(coordinate.longitude * 100)
        return "\(latIndex)-\(lonIndex)"
    }
}
