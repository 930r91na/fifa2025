//
//  DENUEModel.swift
//  fifa2025
//
//  Created by Georgina on 11/10/25.
//

import Foundation

// The model now matches the detailed JSON response from the DENUE API.
struct DENUEBusiness: Codable {
    let id: String
    let name: String
    let businessCategory: String
    let address: String?
    let phoneNumber: String?
    let website: String?
    let latitude: String
    let longitude: String

    // Map the snake_case keys from the JSON to our camelCase properties
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Nombre"
        case businessCategory = "Clase_actividad"
        case address = "Ubicacion"
        case phoneNumber = "Telefono"
        case website = "Sitio_internet"
        case latitude = "Latitud"
        case longitude = "Longitud"
    }
}
