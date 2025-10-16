//
//  AlbumView.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//


import SwiftUI
import Combine

// MARK: - ViewModel del Álbum
class AlbumViewModel: ObservableObject {
    @Published var recentCards: [WorldCupCard] = []
    @Published var allCards: [WorldCupCard] = []
    @Published var selectedCard: WorldCupCard?
    
    init() {
        loadSampleCards()
    }
    
    private func loadSampleCards() {
        recentCards = [
            // ... (your sample card data remains the same) ...
            WorldCupCard(id: UUID(), title: "Estadio Azteca", subtitle: "Ciudad de México", hostCountry: "🇲🇽 México", imageName: "azteca", cardType: .stadium, rarity: .legendary, isOwned: true, duplicateCount: 2),
            WorldCupCard(id: UUID(), title: "Estadio BBVA", subtitle: "Monterrey", hostCountry: "🇲🇽 México", imageName: "azteca1", cardType: .stadium, rarity: .epic, isOwned: true, duplicateCount: 1),
            WorldCupCard(id: UUID(), title: "Estadio Akron", subtitle: "Guadalajara", hostCountry: "🇲🇽 México", imageName: "user2", cardType: .stadium, rarity: .rare, isOwned: true, duplicateCount: 0),
            WorldCupCard(id: UUID(), title: "MetLife Stadium", subtitle: "New York/New Jersey", hostCountry: "🇺🇸 USA", imageName: "user3", cardType: .stadium, rarity: .legendary, isOwned: true, duplicateCount: 3),
            WorldCupCard(id: UUID(), title: "SoFi Stadium", subtitle: "Los Angeles", hostCountry: "🇺🇸 USA", imageName: "cafe1", cardType: .stadium, rarity: .epic, isOwned: true, duplicateCount: 1),
            WorldCupCard(id: UUID(), title: "BMO Field", subtitle: "Toronto", hostCountry: "🇨🇦 Canadá", imageName: "user1", cardType: .stadium, rarity: .rare, isOwned: true, duplicateCount: 0),
            WorldCupCard(id: UUID(), title: "México", subtitle: "CONCACAF", hostCountry: "🇲🇽 México", imageName: "user2", cardType: .country, rarity: .legendary, isOwned: true, duplicateCount: 5),
            WorldCupCard(id: UUID(), title: "Argentina", subtitle: "CONMEBOL", hostCountry: "🇦🇷 Argentina", imageName: "user3", cardType: .country, rarity: .legendary, isOwned: true, duplicateCount: 2),
        ]
        
        allCards = recentCards
    }
}

// MARK: - Vista Principal del Álbum
struct AlbumView: View {
    @StateObject private var viewModel = AlbumViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("FWC26")
                            .font(.title.weight(.heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                        
                        AlbumStatsView()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cartas recientes")
                                .fontWeight(.medium)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            // Pass the viewModel to the carousel
                            AlbumCarouselView(viewModel: viewModel)
                        }
                        
                        AlbumCollectionGridView()
                    }
                    .padding(.vertical)
                }
            }
            .background(Color("BackgroudColor").ignoresSafeArea())
            // **FIX #3: Add a fullScreenCover to present the selected card.**
            // This observes viewModel.selectedCard and presents the FullImageView when it's not nil.
            .fullScreenCover(item: $viewModel.selectedCard) { card in
                FullImageView(card: card)
            }
        }
    }
}


// MARK: - Carrusel de Cartas
struct AlbumCarouselView: View {
    @ObservedObject var viewModel: AlbumViewModel
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        // **FIX #1: Wrap the Carousel and Share Button in a VStack.**
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let cardWidth = geometry.size.width * 0.75
                let peekAmount: CGFloat = 40
                
                ZStack {
                    ForEach(Array(viewModel.recentCards.enumerated()), id: \.element.id) { index, card in
                        let distance = CGFloat(index - currentIndex)
                        let offset = distance * (cardWidth - peekAmount) + dragOffset
                        let scale = getScale(for: index)
                        let opacity = getOpacity(for: index)
                        
                        WorldCupCardView(card: card, viewModel: viewModel)
                            .frame(width: cardWidth)
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .offset(x: offset)
                            .zIndex(index == currentIndex ? 10 : Double(5 - abs(index - currentIndex)))
                            .onTapGesture {
                                if index == currentIndex {
                                    viewModel.selectedCard = card
                                }
                            }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if abs(value.translation.width) > abs(value.translation.height) {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else {
                                withAnimation { dragOffset = 0 }
                                return
                            }
                            
                            let threshold: CGFloat = 50
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if value.translation.width < -threshold && currentIndex < viewModel.recentCards.count - 1 {
                                    currentIndex += 1
                                } else if value.translation.width > threshold && currentIndex > 0 {
                                    currentIndex -= 1
                                }
                                dragOffset = 0
                            }
                        }
                )
            }
            .frame(height: 440) // Adjusted height to fit card
            
            // It uses the card at the `currentIndex` to share the correct one.
            if let currentCard = viewModel.recentCards[safe: currentIndex] {
                ShareLink(
                    item: currentCard,
                    preview: SharePreview(
                        currentCard.title,
                        image: Image(currentCard.imageName)
                    )
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 20))
                        Text("Share Card")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#B1E902"), Color(hex: "#90C700")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "#B1E902").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Helper to safely access array elements
    
    private func getScale(for index: Int) -> CGFloat {
        let distance = abs(currentIndex - index)
        if distance == 0 { return 1.0 }
        else if distance == 1 { return 0.88 }
        else { return 0.75 }
    }
    
    private func getOpacity(for index: Int) -> Double {
        let distance = abs(currentIndex - index)
        if distance >= 2 { return 0 }
        else if distance == 1 { return 0.6 }
        else { return 1.0 }
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ReceivedCardView: View {
    let card: WorldCupCard
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("BackgroudColor").ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("You Received a Card!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)
                
                // Reuse your existing WorldCupCardView
                WorldCupCardView(card: card, viewModel: AlbumViewModel()) // Using a temporary viewModel here
                    .scaleEffect(0.9)

                Button(action: {
                    // TODO: Add logic to save the card to the user's collection
                    print("Adding \(card.title) to collection.")
                    dismiss()
                }) {
                    Text("Add to Album")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#B1E902"))
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Vista de Carta Individual
struct WorldCupCardView: View {
    let card: WorldCupCard
    @ObservedObject var viewModel: AlbumViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Carta con diseño FIFA - IMAGEN DE FONDO COMPLETA
            ZStack {
                // Imagen de fondo ocupando toda la carta
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 380)
                    .clipped()
                
                // Gradiente oscuro para mejorar legibilidad del texto
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.5),
                        Color.clear,
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Borde con el color de rareza
                RoundedRectangle(cornerRadius: 20)
                    .stroke(card.rarity.color, lineWidth: 4)
                
                // Contenido superpuesto
                VStack(spacing: 0) {
                    // Header con tipo de carta y rareza
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: card.cardType.icon)
                                .font(.system(size: 14))
                            Text(card.cardType.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        
                        Spacer()
                        
                        // Rareza badge
                        Text(card.rarity.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(card.rarity.color)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Información en la parte inferior
                    VStack(spacing: 8) {
                       
                        
                        // Título del estadio/país
                        Text(card.title)
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                        
                        // Subtítulo
                        Text(card.subtitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                        
                        // País anfitrión
                        Text(card.hostCountry)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        
                        // Badge de duplicados
                        if card.duplicateCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 13))
                                Text("x\(card.duplicateCount + 1)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(card.rarity.color)
                            .cornerRadius(12)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 420)
            .cornerRadius(20)
        }
        .cornerRadius(20)
        .shadow(color: card.rarity.color.opacity(0.5), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Estadísticas del Álbum
struct AlbumStatsView: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCardView(title: "Estadios", value: "12/16", icon: "building.2.fill", color: Color(hex: "#2F4FFC"))
            StatCardView(title: "Países", value: "28/48", icon: "flag.fill", color: Color(hex: "#B1E902"))
            StatCardView(title: "Duplicados", value: "15", icon: "doc.on.doc.fill", color: Color.orange)
        }
        .padding(.horizontal, 24)
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Grid de Colección
struct AlbumCollectionGridView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tu colección")
                    .fontWeight(.medium)
                Spacer()
                
                HStack (spacing: 2){
                    
                    Text("50/300")
                    
                }
                
                
                
            }
            .font(Font.theme.subheadline)
            .foregroundColor(Color.primaryText)

            ProgressView(value: 0.35)
                .tint(.white)
            
                        
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(26)
    }
}

struct MiniCardView: View {
    let card: WorldCupCard
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.rarity.gradient)
                
                VStack(spacing: 4) {
                    Image(systemName: card.cardType.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Image(card.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 12)
                
                if card.duplicateCount > 0 {
                    Text("x\(card.duplicateCount + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(6)
                }
            }
            .frame(height: 110)
            
            Text(card.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Vista de Imagen Completa (Pop-up)
struct FullImageView: View {
    let card: WorldCupCard
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Botón cerrar
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Imagen ampliada con zoom
                Image(card.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(card.rarity.color, lineWidth: 4)
                    )
                    .shadow(color: card.rarity.color.opacity(0.6), radius: 20, x: 0, y: 10)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    scale = 1.0
                                }
                            }
                    )
                    .padding()
                
                // Info de la carta
                VStack(spacing: 8) {
                    Text(card.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(card.subtitle)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(card.rarity.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(card.rarity.color)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Share Sheet (AirDrop, etc.)
struct ShareSheet: UIViewControllerRepresentable {
    let card: WorldCupCard
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let text = "¡Mira esta carta de mi álbum FIFA 2026! 🏆\n\n\(card.title) - \(card.subtitle)\nRareza: \(card.rarity.rawValue)\n\n¿Quieres intercambiar?"
        
        let items: [Any] = [text]
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Incluir AirDrop y opciones de compartir
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .saveToCameraRoll
        ]
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


