//
//  CalendarManager.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//

import Foundation
internal import EventKit
import Combine


class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    @Published var events: [Event] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    init() {
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() {
        eventStore.requestFullAccessToEvents { (granted, error) in
            DispatchQueue.main.async {
                self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                if granted {
                    self.fetchEvents()
                }
            }
        }
    }

    func fetchEvents() {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            print("Calendar access not granted.")
            return
        }

        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: startDate)! // Look 3 days ahead
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

        let calendarEvents = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.events = calendarEvents.map {
                Event(
                    title: $0.title ?? "Untitled",
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    location: $0.location
                )
            }
        }
    }
    
    // NUEVO: Método para agregar SmartItinerarySuggestion
    func addSmartItinerary(_ suggestion: SmartItinerarySuggestion, completion: @escaping (Bool) -> Void) {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            print("Cannot add event, calendar access not granted.")
            completion(false)
            return
        }
        
        guard let firstStop = suggestion.places.first,
              let lastStop = suggestion.places.last else {
            completion(false)
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "Itinerario: \(suggestion.places.count) lugares"
        event.startDate = firstStop.arrivalTime
        event.endDate = lastStop.departureTime
        event.location = firstStop.place.name
        
        // Agregar notas con todos los lugares
        let placesDescription = suggestion.places.enumerated().map { index, stop in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let time = formatter.string(from: stop.arrivalTime)
            return "\(index + 1). \(time) - \(stop.place.name)"
        }.joined(separator: "\n")
        
        event.notes = "Itinerario sugerido:\n\n\(placesDescription)\n\nDuración total: \(formatDuration(suggestion.totalDuration))\nDistancia: \(String(format: "%.1f", suggestion.totalDistance)) km"
        
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Itinerary event saved to calendar.")
            completion(true)
        } catch {
            print("❌ Failed to save event with error: \(error)")
            completion(false)
        }
    }
    
    // NUEVO: Método para agregar Event genérico
    func addEvent(event: Event, completion: @escaping (Bool) -> Void) {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            print("Cannot add event, calendar access not granted.")
            completion(false)
            return
        }

        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.location = event.location
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(ekEvent, span: .thisEvent)
            print("✅ Event saved to calendar.")
            completion(true)
        } catch {
            print("❌ Failed to save event with error: \(error)")
            completion(false)
        }
    }
    
    // Helper para formatear duración
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
