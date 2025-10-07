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



    func startUpdatesIfNeeded() {
        if isAuthorized() {
            locationManager.startUpdatingLocation()
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
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
}
