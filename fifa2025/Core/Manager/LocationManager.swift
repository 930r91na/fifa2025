//
//  LocationManager.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import CoreLocation
import Combine

class SimpleLocationService: ObservableObject {
    @Published var location: CLLocation
    
    // ✅ Ubicaciones expandidas de CDMX
    enum PresetLocation: CaseIterable {
        // Zonas populares
        case cdmxCentro
        case cdmxPolanco
        case cdmxCondesa
        case cdmxRoma
        case cdmxCoyoacan
        case cdmxSantaFe
        case cdmxReforma
        
        // Estadios (Para Mundial 2026)
        case estadioAzteca
        case estadioAkron         // En Guadalajara, pero útil para referencia
        case autódromoHermanos   // Magdalena Mixhuca
        
        // Museos y cultura
        case museoAntropologia
        case museoBellasArtes
        case museoFridaKahlo
        case museoSoumaya
        case chapultepec
        
        // Zonas comerciales
        case zonaRosa
        case sanAngel
        
        var coordinate: CLLocationCoordinate2D {
            switch self {
            // Zonas populares
            case .cdmxCentro:
                return CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
            case .cdmxPolanco:
                return CLLocationCoordinate2D(latitude: 19.4342, longitude: -99.1962)
            case .cdmxCondesa:
                return CLLocationCoordinate2D(latitude: 19.4120, longitude: -99.1720)
            case .cdmxRoma:
                return CLLocationCoordinate2D(latitude: 19.4190, longitude: -99.1670)
            case .cdmxCoyoacan:
                return CLLocationCoordinate2D(latitude: 19.3467, longitude: -99.1618)
            case .cdmxSantaFe:
                return CLLocationCoordinate2D(latitude: 19.3595, longitude: -99.2590)
            case .cdmxReforma:
                return CLLocationCoordinate2D(latitude: 19.4270, longitude: -99.1677)
                
            // Estadios
            case .estadioAzteca:
                return CLLocationCoordinate2D(latitude: 19.3029, longitude: -99.1506)
            case .estadioAkron:
                return CLLocationCoordinate2D(latitude: 20.6868, longitude: -103.3277) // Guadalajara
            case .autódromoHermanos:
                return CLLocationCoordinate2D(latitude: 19.4082, longitude: -99.0914)
                
            // Museos y cultura
            case .museoAntropologia:
                return CLLocationCoordinate2D(latitude: 19.4260, longitude: -99.1862)
            case .museoBellasArtes:
                return CLLocationCoordinate2D(latitude: 19.4352, longitude: -99.1412)
            case .museoFridaKahlo:
                return CLLocationCoordinate2D(latitude: 19.3551, longitude: -99.1626)
            case .museoSoumaya:
                return CLLocationCoordinate2D(latitude: 19.4406, longitude: -99.2063)
            case .chapultepec:
                return CLLocationCoordinate2D(latitude: 19.4204, longitude: -99.1955)
                
            // Zonas comerciales
            case .zonaRosa:
                return CLLocationCoordinate2D(latitude: 19.4284, longitude: -99.1639)
            case .sanAngel:
                return CLLocationCoordinate2D(latitude: 19.3489, longitude: -99.1892)
            }
        }
        
        var name: String {
            switch self {
            case .cdmxCentro: return "Centro Histórico"
            case .cdmxPolanco: return "Polanco"
            case .cdmxCondesa: return "Condesa"
            case .cdmxRoma: return "Roma"
            case .cdmxCoyoacan: return "Coyoacán"
            case .cdmxSantaFe: return "Santa Fe"
            case .cdmxReforma: return "Reforma"
            case .estadioAzteca: return "Estadio Azteca"
            case .estadioAkron: return "Estadio Akron"
            case .autódromoHermanos: return "Autódromo Hermanos Rodríguez"
            case .museoAntropologia: return "Museo de Antropología"
            case .museoBellasArtes: return "Palacio de Bellas Artes"
            case .museoFridaKahlo: return "Casa Azul (Frida Kahlo)"
            case .museoSoumaya: return "Museo Soumaya"
            case .chapultepec: return "Bosque de Chapultepec"
            case .zonaRosa: return "Zona Rosa"
            case .sanAngel: return "San Ángel"
            }
        }
        
        var emoji: String {
            switch self {
            case .cdmxCentro: return "🏛️"
            case .cdmxPolanco: return "💎"
            case .cdmxCondesa: return "🎨"
            case .cdmxRoma: return "🍽️"
            case .cdmxCoyoacan: return "🎭"
            case .cdmxSantaFe: return "🏢"
            case .cdmxReforma: return "🌳"
            case .estadioAzteca: return "⚽"
            case .estadioAkron: return "🏟️"
            case .autódromoHermanos: return "🏎️"
            case .museoAntropologia: return "🗿"
            case .museoBellasArtes: return "🎨"
            case .museoFridaKahlo: return "🖼️"
            case .museoSoumaya: return "🏛️"
            case .chapultepec: return "🌲"
            case .zonaRosa: return "🛍️"
            case .sanAngel: return "🎪"
            }
        }
        
        var category: LocationCategory {
            switch self {
            case .cdmxCentro, .cdmxPolanco, .cdmxCondesa, .cdmxRoma, .cdmxCoyoacan, .cdmxReforma:
                return .neighborhood
            case .cdmxSantaFe, .zonaRosa:
                return .commercial
            case .estadioAzteca, .estadioAkron, .autódromoHermanos:
                return .stadium
            case .museoAntropologia, .museoBellasArtes, .museoFridaKahlo, .museoSoumaya:
                return .museum
            case .chapultepec, .sanAngel:
                return .park
            }
        }
    }
    
    enum LocationCategory {
        case neighborhood
        case commercial
        case stadium
        case museum
        case park
        
        var displayName: String {
            switch self {
            case .neighborhood: return "Colonias"
            case .commercial: return "Zonas Comerciales"
            case .stadium: return "Estadios"
            case .museum: return "Museos"
            case .park: return "Parques"
            }
        }
    }
    
    init(preset: PresetLocation = .cdmxCentro) {
        let coord = preset.coordinate
        self.location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        print("📍 Ubicación fija: \(preset.name) (\(coord.latitude), \(coord.longitude))")
    }
    
    func setLocation(_ preset: PresetLocation) {
        let coord = preset.coordinate
        self.location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        print("📍 Ubicación actualizada: \(preset.name)")
    }
    
    func setCustomLocation(latitude: Double, longitude: Double) {
        self.location = CLLocation(latitude: latitude, longitude: longitude)
        print("📍 Ubicación personalizada: (\(latitude), \(longitude))")
    }
    
    // ✅ Helper: Obtener ubicaciones por categoría
    static func locations(for category: LocationCategory) -> [PresetLocation] {
        return PresetLocation.allCases.filter { $0.category == category }
    }
}
