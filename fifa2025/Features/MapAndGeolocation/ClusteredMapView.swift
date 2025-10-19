//
//  ClusteredMapView.swift
//  fifa2025
//
//  Created by Georgina on 16/10/25.
//

import SwiftUI
import MapKit

struct ClusteredMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let locations: [MapLocation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(ClusteringAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.region.center.latitude != region.center.latitude || uiView.region.span.latitudeDelta != region.span.latitudeDelta {
            uiView.setRegion(region, animated: true)
        }
        
        let oldAnnotations = uiView.annotations.compactMap { $0 as? MapAnnotation }
        let oldLocationIds = Set(oldAnnotations.map { $0.title })
        let newLocationIds = Set(locations.map { $0.name })

        let annotationsToRemove = oldAnnotations.filter { !newLocationIds.contains($0.title ?? "") }
        if !annotationsToRemove.isEmpty {
            uiView.removeAnnotations(annotationsToRemove)
        }

        let annotationsToAdd = locations
            .filter { !oldLocationIds.contains($0.name) }
            .map { MapAnnotation(location: $0) }
        
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
    }
}


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
        canShowCallout = true
    }
}
