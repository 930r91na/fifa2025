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
    @Published var suggestions: [SmartItinerarySuggestion] = []
    @Published var calendarAuthorizationStatus: EKAuthorizationStatus
    @Published var showScheduleAlert = false
    @Published var scheduleAlertMessage = ""
    @Published var isGeneratingCSV = false
    @Published var showCSVAlert = false
    @Published var csvErrorMessage: String?
    @Published var csvURL: URL?
    @Published var currentCSVProgress: String = ""
    
    // ✅ USAR SINGLETON - NO crear instancias nuevas
    private let userDataManager = UserDataManager.shared
    private let calendarManager = CalendarManager()
    private let locationService = SharedLocationService.shared
    
    private let placesManager = PlacesManager()
    private let inegiManager = INEGICSVManager()
    private var cancellables = Set<AnyCancellable>()
    
    private var lastGoogleCSVPath: URL?
    
    init() {
        self.calendarAuthorizationStatus = calendarManager.authorizationStatus
        
        calendarManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$calendarAuthorizationStatus)
        
        print("📍 HomeViewModel: Usando SharedLocationService.shared")
    }
    
    func loadInitialData() async {
        // ✅ Escuchar cambios de ubicación del singleton
        Publishers.CombineLatest(
            calendarManager.$events,
            locationService.$location
        )
        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
        .sink { [weak self] (events, userLocation) in
            print("🔄 HomeView regenerando - Ubicación: (\(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude))")
            self?.regenerateSuggestions(events: events, userLocation: userLocation)
        }
        .store(in: &cancellables)
        
        calendarManager.fetchEvents()
    }
    
    // MARK: - CSV Generation (sin cambios)
    enum CSVType {
        case googleOnly
        case inegiOnly
        case merged
    }
    
    enum CSVCoverageOption {
        case standard
        case touristZones
        case fullCoverage
    }

    func generateCSV(type: CSVType, coverage: CSVCoverageOption = .touristZones) {
        guard !isGeneratingCSV else { return }
        
        isGeneratingCSV = true
        csvErrorMessage = nil
        currentCSVProgress = "Iniciando..."
        
        Task {
            do {
                var url: URL?
                
                switch type {
                case .googleOnly:
                    currentCSVProgress = "📍 Generando CSV de Google Places..."
                    url = try await placesManager.generateCSVTouristZones()
                    lastGoogleCSVPath = url
                    
                case .inegiOnly:
                    currentCSVProgress = "🏛️ Generando CSV de INEGI..."
                    url = try await inegiManager.generateINEGICSV()
                    
                case .merged:
                    currentCSVProgress = "🔄 Paso 1/2: Generando CSV de Google Places..."
                    let googleURL = try await placesManager.generateCSVTouristZones()
                    lastGoogleCSVPath = googleURL
                    
                    currentCSVProgress = "🔄 Paso 2/2: Fusionando con datos de INEGI..."
                    url = try await inegiManager.generateMergedCSV(googleCSVPath: googleURL)
                }
                
                await MainActor.run {
                    if let url = url {
                        self.csvURL = url
                        self.csvErrorMessage = nil
                        
                        switch type {
                        case .googleOnly:
                            self.scheduleAlertMessage = "✅ CSV de Google Places generado exitosamente"
                        case .inegiOnly:
                            self.scheduleAlertMessage = "✅ CSV de INEGI generado exitosamente"
                        case .merged:
                            self.scheduleAlertMessage = "✅ CSV combinado (Google + INEGI) generado exitosamente"
                        }
                    }
                    self.showCSVAlert = true
                    self.isGeneratingCSV = false
                    self.currentCSVProgress = ""
                }
            } catch {
                print("❌ Error generando CSV: \(error)")
                await MainActor.run {
                    self.csvErrorMessage = "Error al generar el CSV: \(error.localizedDescription)"
                    self.showCSVAlert = true
                    self.isGeneratingCSV = false
                    self.currentCSVProgress = ""
                }
            }
        }
    }
    
    func generateCSVManually(option: CSVCoverageOption = .touristZones) {
        generateCSV(type: .googleOnly, coverage: option)
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
    
    func scheduleSuggestion(_ suggestion: SmartItinerarySuggestion) {
        calendarManager.addSmartItinerary(suggestion) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.scheduleAlertMessage = "¡Itinerario agregado a tu calendario!"
                } else {
                    self?.scheduleAlertMessage = "No se pudo agregar el evento. Verifica los permisos del calendario."
                }
                self?.showScheduleAlert = true
            }
        }
    }
    
    private func regenerateSuggestions(events: [Event], userLocation: CLLocation) {
        let now = Date()
        let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60 - 1)
        
        let freeSlots = SuggestionEngine.findFreeTimeSlots(events: events, from: now, to: endOfDay)
        
        let allLocations = SuggestionEngine.loadAllLocations()
        
        print("📍 Regenerando desde: (\(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude))")
        print("📊 Locations: \(allLocations.count), Free slots: \(freeSlots.count)")
        
        self.suggestions = SuggestionEngine.generateSmartSuggestions(
            for: freeSlots,
            from: userLocation,
            for: userDataManager.user,
            allLocations: allLocations
        )
        
        print("✅ \(self.suggestions.count) sugerencias generadas")
    }
    
    func shareCSV() {
        guard let url = csvURL else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    // ✅ SIMPLIFICADO: Cambia ubicación en el singleton
    func changeTestLocation(to preset: SharedLocationService.PresetLocation) {
        print("🔄 HomeView: Cambiando ubicación global a: \(preset.name)")
        locationService.setLocation(preset)
        // El cambio se propaga automáticamente a:
        // - HomeView (sugerencias)
        // - ItineraryMapViewDirect (mapa)
        // - ProfileView (selector)
    }
}
