//
//  Event.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//
import Foundation

struct Event: Identifiable, Equatable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    
    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, location: String? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
    }
}
