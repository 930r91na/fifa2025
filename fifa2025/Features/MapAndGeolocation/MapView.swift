import SwiftUI
import MapKit

struct MapView: View {

    @StateObject private var viewModel = MapViewModel()
    @State private var selectedLocation: MapLocation?

    var body: some View {
        ZStack {
            Map(coordinateRegion: $viewModel.mapRegion,
                annotationItems: viewModel.filteredLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    MapAnnotationView(locationType: location.type)
                        .scaleEffect(selectedLocation?.id == location.id ? 1.0 : 0.7)
                        .shadow(radius: 10)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                self.selectedLocation = location
                            }
                        }
                }
            }
            .ignoresSafeArea()

            VStack {
                FilterButtonsView(viewModel: viewModel)
                    .padding(.top)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }

                if let location = selectedLocation {
                    LocationDetailView(location: location, isShowingDetail: $selectedLocation)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 25.0).fill(.ultraThinMaterial))
                        .shadow(radius: 10)
                        .padding(.horizontal)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .bottom))
                        )
                }
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
}

// MARK: - Placeholder Subviews

struct FilterButtonsView: View {
    @ObservedObject var viewModel: MapViewModel // Correct way to pass a ViewModel to a subview

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(LocationType.allCases) { type in
                    Button(action: {
                        viewModel.toggleFilter(for: type)
                    }) {
                        Label(type.type, systemImage: type.sfSymbol)
                            .padding(8)
                            .background(viewModel.selectedFilters.contains(type) ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MapAnnotationView: View {
    let locationType: LocationType
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: locationType.sfSymbol)
                .font(.title2)
                .padding(10)
                .background(Color("FifaCompRed"))
                .foregroundColor(.white)
                .clipShape(Circle())
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color("FifaCompRed"))
                .frame(width: 10, height: 10)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -3)
        }
    }
}

struct LocationDetailView: View {
    let location: MapLocation
    @Binding var isShowingDetail: MapLocation?
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
