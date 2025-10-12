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
                Event(title: $0.title, startDate: $0.startDate, endDate: $0.endDate)
            }
        }
    }
    
    func addEvent(suggestion: ItinerarySuggestion, completion: @escaping (Bool) -> Void) {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            print("Cannot add event, calendar access not granted.")
            completion(false)
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "Visit \(suggestion.location.name)"
        event.startDate = suggestion.freeTimeSlot.start
        // Let's schedule it for an hour by default
        event.endDate = suggestion.freeTimeSlot.start.addingTimeInterval(3600)
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            print("Event saved to calendar.")
            completion(true)
        } catch {
            print("Failed to save event with error: \(error)")
            completion(false)
        }
    }
}
