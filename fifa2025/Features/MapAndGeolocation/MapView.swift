//
//  MapView.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // The main map view
            Map(coordinateRegion: $viewModel.mapRegion,
                showsUserLocation: true,
                annotationItems: viewModel.filteredLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    LocationMapAnnotationView(locationType: location.type)
                        .scaleEffect(viewModel.selectedLocation?.id == location.id ? 1.2 : 0.8)
                        .shadow(radius: 10)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.selectedLocation = location
                            }
                        }
                }
            }
            .ignoresSafeArea()
            
            // UI Overlays
            VStack {
                FilterBarView(
                    activeFilters: $viewModel.activeFilters,
                    showWomenInSportsOnly: $viewModel.showWomenInSportsOnly,
                    onToggleFilter: viewModel.toggleFilter,
                    onToggleWomenInSports: viewModel.toggleWomenInSportsFilter
                )
                .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.centerOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.primary.opacity(0.75))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $viewModel.selectedLocation) { location in
            LocationDetailView(location: location)
                .presentationDetents([.height(250), .medium])
        }
    }
}

// MARK: - Subviews

struct LocationMapAnnotationView: View {
    let locationType: LocationType
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: locationType.sfSymbol)
                .font(.title2)
                .padding(10)
                .background(Color.accentColor.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Circle())
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.accentColor.opacity(0.8))
                .frame(width: 10, height: 10)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -3)
        }
    }
}

struct FilterBarView: View {
    @Binding var activeFilters: Set<LocationType>
    @Binding var showWomenInSportsOnly: Bool
    
    var onToggleFilter: (LocationType) -> Void
    var onToggleWomenInSports: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Women in Sports Toggle
                Button(action: onToggleWomenInSports) {
                    Label("Women in Sports", systemImage: showWomenInSportsOnly ? "checkmark.square.fill" : "square")
                }
                .buttonStyle(FilterButtonStyle(isActive: showWomenInSportsOnly))
                
                // Category Toggles
                ForEach(LocationType.allCases) { type in
                    Button(action: {
                        onToggleFilter(type)
                    }) {
                        // Use a Label to combine the icon and text
                        Label(type.type, systemImage: type.sfSymbol)
                    }
                    .buttonStyle(FilterButtonStyle(isActive: activeFilters.contains(type)))
                }
            }
            .padding(8)
            .background(.thinMaterial)
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
}

struct FilterButtonStyle: ButtonStyle {
    var isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Color.accentColor : Color.secondary.opacity(0.3))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isActive)
    }
}


struct LocationDetailView: View {
    let location: MapLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(location.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(location.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if location.promotesWomenInSports {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("This location highlights women in sports.")
                        .font(.headline)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    MapView()
}
