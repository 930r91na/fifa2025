import Foundation
import CoreLocation
import Combine

// MARK: - SharedLocationService (Singleton compartido entre vistas)
final class SharedLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // ⭐ SINGLETON para compartir instancia
    static let shared = SharedLocationService(preset: SharedLocationService.cdmxCentro)
    
    @Published var location: CLLocation
    @Published var currentPreset: PresetLocation
    
    private let locationManager = CLLocationManager()
    private var useRealLocation = false
    
    enum LocationCategory: String, CaseIterable {
        case neighborhood = "Colonias"
        case commercial = "Zonas Comerciales"
        case stadium = "Estadios"
        case museum = "Museos"
        case park = "Parques"
        
        var displayName: String { rawValue }
    }
    
    struct PresetLocation: Hashable {
        let name: String
        let emoji: String
        let latitude: Double
        let longitude: Double
        let category: LocationCategory
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    // MARK: - Ubicaciones Predefinidas
    static let cdmxCentro = PresetLocation(
        name: "Centro Histórico",
        emoji: "🏛️",
        latitude: 19.4326,
        longitude: -99.1332,
        category: .neighborhood
    )
    
    static let polanco = PresetLocation(
        name: "Polanco",
        emoji: "💎",
        latitude: 19.4341,
        longitude: -99.1947,
        category: .neighborhood
    )
    
    static let condesa = PresetLocation(
        name: "Condesa",
        emoji: "🌳",
        latitude: 19.4102,
        longitude: -99.1708,
        category: .neighborhood
    )
    
    static let roma = PresetLocation(
        name: "Roma Norte",
        emoji: "🎨",
        latitude: 19.4167,
        longitude: -99.1624,
        category: .neighborhood
    )
    
    static let coyoacan = PresetLocation(
        name: "Coyoacán",
        emoji: "🎭",
        latitude: 19.3503,
        longitude: -99.1623,
        category: .neighborhood
    )
    
    static let santaFe = PresetLocation(
        name: "Santa Fe",
        emoji: "🏢",
        latitude: 19.3593,
        longitude: -99.2587,
        category: .commercial
    )
    
    static let reforma = PresetLocation(
        name: "Reforma",
        emoji: "🌳",
        latitude: 19.4270,
        longitude: -99.1677,
        category: .neighborhood
    )
    
    static let insurgentes = PresetLocation(
        name: "Insurgentes Sur",
        emoji: "🛍️",
        latitude: 19.3620,
        longitude: -99.1780,
        category: .commercial
    )
    
    static let zonaRosa = PresetLocation(
        name: "Zona Rosa",
        emoji: "🛍️",
        latitude: 19.4284,
        longitude: -99.1639,
        category: .commercial
    )
    
    // Estadios
    static let azteca = PresetLocation(
        name: "Estadio Azteca",
        emoji: "⚽",
        latitude: 19.3029,
        longitude: -99.1506,
        category: .stadium
    )
    
    static let akron = PresetLocation(
        name: "Estadio Akron",
        emoji: "🏟️",
        latitude: 20.5428,
        longitude: -103.4626,
        category: .stadium
    )
    
    static let autodromo = PresetLocation(
        name: "Autódromo Hermanos Rodríguez",
        emoji: "🏎️",
        latitude: 19.4082,
        longitude: -99.0914,
        category: .stadium
    )
    
    // Museos
    static let antropologia = PresetLocation(
        name: "Museo de Antropología",
        emoji: "🗿",
        latitude: 19.4259,
        longitude: -99.1862,
        category: .museum
    )
    
    static let bellas = PresetLocation(
        name: "Palacio de Bellas Artes",
        emoji: "🎭",
        latitude: 19.4353,
        longitude: -99.1412,
        category: .museum
    )
    
    static let fridaKahlo = PresetLocation(
        name: "Casa Azul (Frida Kahlo)",
        emoji: "🖼️",
        latitude: 19.3551,
        longitude: -99.1626,
        category: .museum
    )
    
    static let soumaya = PresetLocation(
        name: "Museo Soumaya",
        emoji: "🏛️",
        latitude: 19.4406,
        longitude: -99.2063,
        category: .museum
    )
    
    // Parques
    static let chapultepec = PresetLocation(
        name: "Bosque de Chapultepec",
        emoji: "🌲",
        latitude: 19.4204,
        longitude: -99.1987,
        category: .park
    )
    
    static let alameda = PresetLocation(
        name: "Alameda Central",
        emoji: "🌿",
        latitude: 19.4356,
        longitude: -99.1426,
        category: .park
    )
    
    static let sanAngel = PresetLocation(
        name: "San Ángel",
        emoji: "🎪",
        latitude: 19.3489,
        longitude: -99.1892,
        category: .park
    )
    
    static func locations(for category: LocationCategory) -> [PresetLocation] {
        let allLocations: [PresetLocation] = [
            // Colonias
            cdmxCentro, polanco, condesa, roma, coyoacan, reforma,
            // Comerciales
            santaFe, insurgentes, zonaRosa,
            // Estadios
            azteca, akron, autodromo,
            // Museos
            antropologia, bellas, fridaKahlo, soumaya,
            // Parques
            chapultepec, alameda, sanAngel
        ]
        
        return allLocations.filter { $0.category == category }
    }
    
    // MARK: - Init
    init(preset: PresetLocation) {
        self.currentPreset = preset
        self.location = CLLocation(
            latitude: preset.latitude,
            longitude: preset.longitude
        )
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        print("📍 SimpleLocationService iniciado en: \(preset.name)")
    }
    
    // MARK: - Cambiar Ubicación
    func setLocation(_ preset: PresetLocation) {
        print("🔄 Cambiando a: \(preset.name) (\(preset.latitude), \(preset.longitude))")
        
        currentPreset = preset
        location = CLLocation(
            latitude: preset.latitude,
            longitude: preset.longitude
        )
        
        print("✅ Ubicación actualizada")
    }
    
    // MARK: - Ubicación Real (opcional)
    func useRealLocationIfAvailable() {
        useRealLocation = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard useRealLocation, let newLocation = locations.last else { return }
        
        print("📍 Ubicación real actualizada: (\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude))")
        location = newLocation
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Error obteniendo ubicación: \(error)")
    }
}
