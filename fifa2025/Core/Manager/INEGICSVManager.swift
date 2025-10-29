//
//  INEGICSVManager.swift
//  fifa2025
//
//  Created by Martha Heredia Andrade on 23/10/25.
//


import Foundation
import CoreLocation
import OSLog  // ✅ Agregar este import

class INEGICSVManager {
    private let denueService: DENUEService
    private let apiToken: String
    private let logger = Logger(subsystem: "com.fifa2025.TurismoLocalWC26", category: "INEGICSVManager")  // ✅ Ahora funciona
    
    // Header para CSV de INEGI (compatible con el de Google Places)
    private let inegiCSVHeader = "source,primary_type,name,types,rating,user_ratings_total,price_level,price_range_min,price_range_max,lat,lng,photo_uri,opening_hours,website,phone_national,phone_international,google_maps_uri,formatted_address,business_category,denue_id"
    
    init() {
        self.denueService = DENUEService()
        // ✅ API Key directo (más simple y evita errores de configuración)
        self.apiToken = "1d9ed092-cf68-4a25-a030-344140040d5f"
    }
    
    // FUNCIÓN PRINCIPAL: Genera CSV solo de INEGI
    func generateINEGICSV(progressHandler: ((String) -> Void)? = nil) async throws -> URL {
        print("🚀 INICIANDO ESCANEO INEGI/DENUE DE CIUDAD DE MÉXICO")
        print("📊 Generando CSV solo con datos de INEGI\n")
        
        var csvData = [inegiCSVHeader]
        var allBusinesses: Set<String> = []
        let startTime = Date()
        
        let zones = generateCDMXZones()
        
        for (index, zone) in zones.enumerated() {
            let progress = Double(index + 1) / Double(zones.count) * 100
            let progressMessage = "🔍 [\(index+1)/\(zones.count)] [\(String(format: "%.1f", progress))%] \(zone.name)"
            print(progressMessage)
            progressHandler?(progressMessage)
            
            do {
                let businesses = try await fetchINEGIBusinessesForZone(
                    lat: zone.lat,
                    lng: zone.lng,
                    radius: zone.radius
                )
                
                for business in businesses {
                    if !allBusinesses.contains(business.id) {
                        allBusinesses.insert(business.id)
                        let csvRow = convertINEGIToCSVRow(business)
                        csvData.append(csvRow)
                    }
                }
                
                let elapsed = Int(Date().timeIntervalSince(startTime))
                print("   ✅ +\(businesses.count) negocios | Total único: \(allBusinesses.count) | ⏱️ \(elapsed)s")
                
                // Delay para no saturar la API (optimizado)
                try await Task.sleep(nanoseconds: 100_000_000) // ✅ 100ms en vez de 250ms - 2.5x más rápido
            } catch {
                print("   ❌ Error: \(error.localizedDescription)")
                continue
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("\n" + String(repeating: "=", count: 50))
        print("🎉 ESCANEO INEGI COMPLETADO")
        print(String(repeating: "=", count: 50))
        print("📊 Negocios únicos INEGI: \(allBusinesses.count)")
        print("💾 Registros en CSV: \(csvData.count - 1)")
        print("⏱️ Tiempo total: \(String(format: "%.1f", duration / 60)) minutos")
        print(String(repeating: "=", count: 50) + "\n")
        
        return try saveCSV(data: csvData, filename: "inegi_only_dataset")
    }
    
    // FUNCIÓN PARA FUSIONAR CSVs
    func generateMergedCSV(googleCSVPath: URL) async throws -> URL {
        print("🔄 INICIANDO FUSIÓN DE DATOS")
        print("📊 Fusionando Google Places + INEGI\n")
        
        let startTime = Date()
        
        // 1. Leer CSV de Google Places
        print("📖 Leyendo datos de Google Places...")
        let googleData = try String(contentsOf: googleCSVPath, encoding: .utf8)
        let googleLines = googleData.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        // 2. Obtener datos de INEGI
        print("🔍 Obteniendo datos de INEGI...")
        var inegiBusinesses: [DENUEBusiness] = []
        let zones = generateCDMXZones()
        
        for (index, zone) in zones.enumerated() {
            let progress = Double(index + 1) / Double(zones.count) * 100
            print("   [\(index+1)/\(zones.count)] [\(String(format: "%.1f", progress))%] \(zone.name)")
            
            do {
                let businesses = try await fetchINEGIBusinessesForZone(
                    lat: zone.lat,
                    lng: zone.lng,
                    radius: zone.radius
                )
                inegiBusinesses.append(contentsOf: businesses)
                try await Task.sleep(nanoseconds: 250_000_000)
            } catch {
                continue
            }
        }
        
        // 3. Eliminar duplicados de INEGI usando IDs únicos
        var seenIDs = Set<String>()
        let uniqueINEGI = inegiBusinesses.filter { business in
            if seenIDs.contains(business.id) {
                return false
            } else {
                seenIDs.insert(business.id)
                return true
            }
        }
        
        // 4. Crear CSV combinado
        var mergedData = [inegiCSVHeader]
        
        // Agregar datos de Google (saltando header)
        for line in googleLines.dropFirst() {
            if !line.isEmpty {
                mergedData.append(line)
            }
        }
        
        // Agregar datos de INEGI
        for business in uniqueINEGI {
            let csvRow = convertINEGIToCSVRow(business)
            mergedData.append(csvRow)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("\n" + String(repeating: "=", count: 50))
        print("🎉 FUSIÓN COMPLETADA")
        print(String(repeating: "=", count: 50))
        print("📊 Lugares de Google Places: \(googleLines.count - 1)")
        print("📊 Lugares de INEGI: \(uniqueINEGI.count)")
        print("📊 TOTAL COMBINADO: \(mergedData.count - 1)")
        print("⏱️ Tiempo total: \(String(format: "%.1f", duration / 60)) minutos")
        print(String(repeating: "=", count: 50) + "\n")
        
        return try saveCSV(data: mergedData, filename: "merged_google_inegi_dataset")
    }
    
    // Fetch negocios de INEGI para una zona específica (OPTIMIZADO con concurrencia)
    private func fetchINEGIBusinessesForZone(lat: Double, lng: Double, radius: Double) async throws -> [DENUEBusiness] {
        // Todas las categorías de INEGI
        let categories: [LocationType] = [.food, .shop, .cultural, .stadium, .entertainment, .souvenirs]
        
        // ✅ Procesamiento concurrente con TaskGroup
        return await withTaskGroup(of: [DENUEBusiness].self, returning: [DENUEBusiness].self) { group in
            var allBusinesses: [DENUEBusiness] = []
            
            for category in categories {
                let keywords = getKeywords(for: category)
                
                for keyword in keywords {
                    group.addTask {
                        let urlString = "https://www.inegi.org.mx/app/api/denue/v1/consulta/buscar/\(keyword)/\(lat),\(lng)/\(Int(radius))/\(self.apiToken)"
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        
                        guard let url = URL(string: urlString) else { return [] }
                        
                        do {
                            var request = URLRequest(url: url)
                            request.timeoutInterval = 10.0  // ✅ Reducido de 20s a 10s
                            
                            let (data, response) = try await URLSession.shared.data(for: request)
                            
                            guard let httpResponse = response as? HTTPURLResponse,
                                  200..<300 ~= httpResponse.statusCode else {
                                return []
                            }
                            
                            let businesses = try JSONDecoder().decode([DENUEBusiness].self, from: data)
                            return businesses
                            
                        } catch {
                            // Silenciar errores individuales para no detener todo el proceso
                            return []
                        }
                    }
                }
            }
            
            // Recolectar todos los resultados
            for await result in group {
                allBusinesses.append(contentsOf: result)
            }
            
            return allBusinesses
        }
    }
    
    // Convertir DENUEBusiness a fila CSV
    private func convertINEGIToCSVRow(_ business: DENUEBusiness) -> String {
        let locationType = mapBusinessTypeToLocationType(business.businessCategory)
        
        // ✅ Especificar tipo explícitamente
        let fields: [String] = [
            "INEGI",                                    // source
            String(describing: locationType.rawValue),  // primary_type ✅ Convertir a String
            business.name.capitalized,                  // name
            business.businessCategory,                  // types
            "N/A",                                      // rating (INEGI no tiene)
            "N/A",                                      // user_ratings_total
            "N/A",                                      // price_level
            "",                                         // price_range_min
            "",                                         // price_range_max
            String(business.latitude),                  // lat ✅ Convertir a String
            String(business.longitude),                 // lng ✅ Convertir a String
            "",                                         // photo_uri (INEGI no tiene)
            "N/A",                                      // opening_hours (INEGI no tiene)
            business.website ?? "",                     // website
            business.phoneNumber ?? "",                 // phone_national
            "",                                         // phone_international
            "",                                         // google_maps_uri
            business.address ?? "",                     // formatted_address
            business.businessCategory,                  // business_category
            business.id                                 // denue_id
        ]
        
        return fields.map { escapeCSV($0) }.map { "\"\($0)\"" }.joined(separator: ",")
    }
    
  
    private func getKeywords(for type: LocationType) -> [String] {
        switch type {
        case .food:
            return ["restaurantes", "cafeterías", "taquerías", "comida"]
        case .shop:
            return ["artesanías", "ropa", "joyería", "tiendas"]
        case .cultural:
            return ["museos", "galerías", "teatros"]
        case .stadium:
            return ["estadios", "arena"]
        case .entertainment:
            return ["bares", "discotecas", "cines", "entretenimiento"]
        case .souvenirs:
            return ["dulces", "regalos", "recuerdos"]
        case .others:
            return ["turismo"]
        }
    }
    
    // Mapeo de categoría INEGI a LocationType
    private func mapBusinessTypeToLocationType(_ category: String) -> LocationType {
        let lowercased = category.lowercased()
        
        if lowercased.contains("restaurante") || lowercased.contains("cafetería") ||
           lowercased.contains("nevería") || lowercased.contains("taquería") ||
           lowercased.contains("comida") || lowercased.contains("alimento") {
            return .food
        } else if lowercased.contains("bar") || lowercased.contains("discoteca") ||
                  lowercased.contains("nocturno") || lowercased.contains("cine") {
            return .entertainment
        } else if lowercased.contains("ropa") || lowercased.contains("calzado") ||
                  lowercased.contains("joyería") || lowercased.contains("artesanía") {
            return .shop
        } else if lowercased.contains("dulce") || lowercased.contains("regalo") ||
                  lowercased.contains("souvenir") {
            return .souvenirs
        } else if lowercased.contains("museo") || lowercased.contains("galería") ||
                  lowercased.contains("teatro") || lowercased.contains("histórico") {
            return .cultural
        } else if lowercased.contains("estadio") || lowercased.contains("arena") {
            return .stadium
        } else {
            return .others
        }
    }
    
    // Generar zonas de CDMX
    private func generateCDMXZones() -> [(lat: Double, lng: Double, name: String, radius: Double)] {
        var zones: [(Double, Double, String, Double)] = []
        
        // Zonas VIP y turísticas (igual que en PlacesManager)
        let vipZones = [
            (19.4326, -99.1332, "Centro Histórico - Zócalo", 4000.0),
            (19.4200, -99.1719, "Polanco - Masaryk", 4000.0),
            (19.4483, -99.2065, "Chapultepec - Bosque", 5000.0),
            (19.4180, -99.1750, "Zona Rosa - Reforma", 3500.0),
            (19.3623, -99.1763, "Condesa - Parque México", 3500.0),
            (19.3700, -99.1650, "Roma Norte", 3500.0),
            (19.3550, -99.1870, "Coyoacán - Centro", 4000.0),
            (19.3460, -99.1790, "San Ángel", 3500.0),
            (19.3600, -99.2740, "Santa Fe - Centro", 5000.0)
        ]
        
        // Estadios
        let stadiums = [
            (19.3029, -99.1504, "Estadio Azteca", 4000.0),
            (19.4110, -99.2007, "Estadio Azul", 3500.0),
            (19.4733, -99.2467, "Estadio CU", 4000.0)
        ]
        
        // Grid de cobertura completa
        let latMin = 19.2
        let latMax = 19.6
        let lngMin = -99.35
        let lngMax = -99.0
        let gridSize = 0.08 // ✅ BALANCE ÓPTIMO: Buena cobertura (~35 zonas) en tiempo razonable (~10-12 min)
        
        var lat = latMin
        var counter = 1
        
        while lat <= latMax {
            var lng = lngMin
            while lng <= lngMax {
                zones.append((lat, lng, "Grid-\(counter)", 3000.0))
                counter += 1
                lng += gridSize
            }
            lat += gridSize
        }
        
        zones.append(contentsOf: vipZones)
        zones.append(contentsOf: stadiums)
        
        return zones
    }
    
    // Guardar CSV
    private func saveCSV(data: [String], filename: String) throws -> URL {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fullFilename = "\(filename)_\(timestamp).csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fullFilename)
        
        let csvString = data.joined(separator: "\n")
        try csvString.write(to: path, atomically: true, encoding: .utf8)
        
        print("💾 CSV guardado en: \(path.path)")
        return path
    }
    
    private func escapeCSV(_ value: String) -> String {
        return value.replacingOccurrences(of: "\"", with: "\"\"")
    }
}
