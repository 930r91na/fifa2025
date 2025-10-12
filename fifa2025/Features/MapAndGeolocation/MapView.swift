//
//  MapView.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import SwiftUI
import MapKit

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("BackgroudColor").ignoresSafeArea()
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
            .tint(Color.fifaCompRed) // Use theme color for user location dot
            
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
                .presentationDetents([.height(300), .medium])
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Finding local spots...")
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(10)
            } else if let errorMessage = viewModel.errorMessage {
                 // You can create a more elaborate error view
                Text(errorMessage)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(10)
                    .foregroundColor(.red)
            } else if viewModel.locationStatus == .denied {
                 // New view to guide the user
                LocationDeniedView()
            }
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


// This replaces the old LocationDetailView at the bottom of the file
struct LocationDetailView: View {
    let location: MapLocation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading) {
                    Text(location.name)
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(Color.primaryText)
                    Text(location.description) // Business Category
                        .font(.headline)
                        .foregroundColor(Color.secondaryText)
                }
                                
                // Address (only shows if available and not empty)
                if let address = location.address, !address.isEmpty {
                    InfoRow(icon: "mappin.and.ellipse", title: "Address", content: address)
                }
                
                // Phone Number (only shows if available and not empty)
                if let phoneNumber = location.phoneNumber, !phoneNumber.isEmpty {
                    InfoRow(icon: "phone.fill", title: "Phone", content: phoneNumber, isLink: true, linkURL: "tel:\(phoneNumber)")
                }
                
                // Website (only shows if available and not empty)
                if let website = location.website, !website.isEmpty {
                    // A basic check to ensure the URL is valid
                    let validUrlString = website.hasPrefix("http") ? website : "http://\(website)"
                    InfoRow(icon: "safari.fill", title: "Website", content: website, isLink: true, linkURL: validUrlString)
                }

                // Women in sports highlight
                if location.promotesWomenInSports {
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("This location highlights women in sports.").font(.headline)
                    }
                    .padding(.top)
                }
            }
            .padding(30)
        }
        .background(Color.secondaryBackground)
        .ignoresSafeArea()
    }
}

struct LocationDeniedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.largeTitle)
            Text("Location Access Denied")
                .font(.headline)
            Text("Displaying spots in Mexico City by default. To see places near you, please enable location services.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Button to open app settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") {
                    UIApplication.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.fifaCompRed)
                .padding(.top)
            }
        }
        .padding(30)
        .background(.ultraThickMaterial)
        .cornerRadius(16)
        .padding()
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    var isLink: Bool = false
    var linkURL: String? = nil
    
    @Environment(\.openURL) var openURL

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 25)
                .foregroundColor(Color.fifaCompRed)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isLink, let urlString = linkURL, let url = URL(string: urlString) {
                    Button(action: { openURL(url) }) {
                        Text(content)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                } else {
                    Text(content)
                        .fontWeight(.semibold)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    MapView()
}
