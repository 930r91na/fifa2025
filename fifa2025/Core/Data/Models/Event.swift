//
//  Event.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//
import Foundation

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
}
