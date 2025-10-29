//
//  ClusteredMapView.swift
//  fifa2025
//
//  Created by Georgina on 16/10/25.
//

import SwiftUI
import MapKit

// MARK: - ClusteredMapView con Soporte para Selección
struct ClusteredMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let locations: [MapLocation]
    @Binding var selectedLocation: MapLocation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: "CustomAnnotation")
        mapView.register(ClusteringAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.region.center.latitude != region.center.latitude ||
           uiView.region.span.latitudeDelta != region.span.latitudeDelta {
            uiView.setRegion(region, animated: true)
        }
        
        context.coordinator.parent = self
        
        let oldAnnotations = uiView.annotations.compactMap { $0 as? LocationAnnotation }
        let oldLocationIds = Set(oldAnnotations.map { $0.locationID })
        let newLocationIds = Set(locations.map { $0.id })

        let annotationsToRemove = oldAnnotations.filter { !newLocationIds.contains($0.locationID) }
        if !annotationsToRemove.isEmpty {
            uiView.removeAnnotations(annotationsToRemove)
        }

        let annotationsToAdd = locations
            .filter { !oldLocationIds.contains($0.id) }
            .map { LocationAnnotation(location: $0) }
        
        if !annotationsToAdd.isEmpty {
            uiView.addAnnotations(annotationsToAdd)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ClusteredMapView

        init(_ parent: ClusteredMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
        
        // MARK: - Configurar Vista de Anotación
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let locationAnnotation = annotation as? LocationAnnotation else { return nil }
            
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotation") as? CustomAnnotationView {
                annotationView.annotation = annotation
                annotationView.configure(with: locationAnnotation)
                return annotationView
            }
            
            let annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
            annotationView.configure(with: locationAnnotation)
            return annotationView
        }
        
        // MARK: - Manejar Selección de Anotación
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let locationAnnotation = view.annotation as? LocationAnnotation else { return }
            
            // Encontrar la ubicación completa
            if let location = parent.locations.first(where: { $0.id == locationAnnotation.locationID }) {
                DispatchQueue.main.async {
                    self.parent.selectedLocation = location
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            // Opcional: limpiar selección si es necesario
        }
    }
}

// MARK: - Vista de Anotación Personalizada
final class CustomAnnotationView: MKMarkerAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "location"
        collisionMode = .circle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with annotation: LocationAnnotation) {
        // Configurar color según tipo de ubicación
        markerTintColor = colorForLocationType(annotation.locationType)
        glyphImage = UIImage(systemName: annotation.locationType.sfSymbol)
        
        // Habilitar callout con botón de detalle
        canShowCallout = true
        
        // Botón de información
        let infoButton = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = infoButton
        
        // Configurar vista de callout personalizada
        detailCalloutAccessoryView = createDetailView(for: annotation)
    }
    
    private func createDetailView(for annotation: LocationAnnotation) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        
        // Título
        let titleLabel = UILabel()
        titleLabel.text = annotation.title
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        
        // Descripción
        let descLabel = UILabel()
        descLabel.text = annotation.subtitle
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descLabel)
        
        // Agregar información adicional si existe
        if let location = annotation.location {
            if let address = location.address, !address.isEmpty {
                let addressLabel = UILabel()
                addressLabel.text = "📍 \(address)"
                addressLabel.font = .systemFont(ofSize: 12)
                addressLabel.textColor = .systemGray
                addressLabel.numberOfLines = 2
                stackView.addArrangedSubview(addressLabel)
            }
            
            if let phone = location.phoneNumber, !phone.isEmpty {
                let phoneLabel = UILabel()
                phoneLabel.text = "☎️ \(phone)"
                phoneLabel.font = .systemFont(ofSize: 12)
                phoneLabel.textColor = .systemGray
                stackView.addArrangedSubview(phoneLabel)
            }
        }
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.widthAnchor.constraint(equalToConstant: 250).isActive = true
        
        return stackView
    }
    
    private func colorForLocationType(_ type: LocationType) -> UIColor {
        switch type {
        case .food: return .systemOrange
        case .shop: return .systemPurple
        case .cultural: return .systemBlue
        case .stadium: return .systemGreen
        case .entertainment: return .systemPink
        case .souvenirs: return .systemYellow
        case .others: return .systemGray
        }
    }
}

// MARK: - Vista de Cluster
final class ClusteringAnnotationView: MKMarkerAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        clusteringIdentifier = "location"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        if let cluster = annotation as? MKClusterAnnotation {
            markerTintColor = .systemRed
            glyphText = "\(cluster.memberAnnotations.count)"
            canShowCallout = true
        }
    }
}

// MARK: - LocationAnnotation (Reemplaza la clase MapAnnotation anterior)
final class LocationAnnotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let locationType: LocationType
    let locationID: String
    var location: MapLocation?

    init(location: MapLocation) {
        self.title = location.name
        self.subtitle = location.description
        self.coordinate = location.coordinate
        self.locationType = location.type
        self.locationID = location.id
        self.location = location
        super.init()
    }
}
