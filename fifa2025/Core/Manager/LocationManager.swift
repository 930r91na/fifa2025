//
//  LocationManager.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()

    // Mock location for Mexico City (Zocalo)
    private let mockMexicoCityLocation = CLLocation(latitude: 19.4326, longitude: -99.1332)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorization()
    }

    func checkAuthorization() {
        DispatchQueue.main.async {
            self.authorizationStatus = self.locationManager.authorizationStatus
            if self.authorizationStatus == .notDetermined {
                self.requestPermission()
            } else if self.isAuthorized() {
                self.startUpdatesIfNeeded()
            }
        }
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // Call this for real location updates
    func startUpdatesIfNeeded() {
        if isAuthorized() {
            locationManager.startUpdatingLocation()
        }
    }
    
    // Call this to use the mock location for testing
    func startUpdatingLocationWithMock() {
        DispatchQueue.main.async {
            self.location = self.mockMexicoCityLocation
            print("Using mock location: Mexico City")
        }
    }

    func isAuthorized() -> Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - Delegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.location = newLocation
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            // If the user grants permission, you might want to start updates.
            // For testing with mock data, you can decide whether to call startUpdatesIfNeeded() or startUpdatingLocationWithMock()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
}
