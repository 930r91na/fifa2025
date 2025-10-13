//
//  CommunityView.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import SwiftUI
import Combine

struct CommunityView: View {
    @ObservedObject var vm: CommunityViewModel
    private let localUser = UserModel(id: UUID(), username: "me_local", displayName: "You", avatarName: "user_local", country: "Mexico")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo
                
                
                // Contenido principal
                ScrollView {
                    VStack(spacing: 0) {
                        Text("FWC26")
                            .font(.title.weight(.heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 26)
                        
                        Image("component1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 60)
                        
                        // Leaderboard preview
                        LeaderboardPreviewView(entries: vm.leaderboard)
                            .padding(.horizontal)
                            .background(
                                NavigationLink(value: vm.leaderboard) {
                                    EmptyView()
                                }.opacity(0)
                            )
                        
                        // Feed
                        VStack(spacing: 12) {
                            ForEach(vm.posts) { post in
                                PostCardView(
                                    post: post,
                                    onLike: { vm.toggleLike(postId: post.id) },
                                    onAddComment: { text in vm.addComment(postId: post.id, commentText: text, from: localUser) }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color("BackgroudColor").ignoresSafeArea())
            .navigationDestination(for: [LeaderboardEntry].self) { entries in
                LeaderboardFullView(entries: entries)
            }
        }
    }
}
#Preview {
    CommunityView(vm: CommunityViewModel())  // ⬅️ Pasa un VM
}



// MARK: - Leaderboard preview
struct LeaderboardPreviewView: View {
    let entries: [LeaderboardEntry]
    @State private var animateBars = false
    
    // Calcular el máximo de puntos para escalar las barras
    private var maxPoints: Int {
        entries.prefix(3).map { $0.points }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Barras del podio - Orden: 2do, 1ro, 3ro
            HStack(alignment: .bottom, spacing: 12) {
                // Reordenar para mostrar: 3ro - 1ro - 2do
                ForEach(podiumOrder(), id: \.entry.id) { item in
                    VStack(spacing: 2) {
                        // Bandera arriba
                        Text(item.entry.flagEmoji)
                            .font(.system(size: 32))
                            .padding(.bottom, 8)
                        
                        // Barra con gradiente
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: barColors(for: item.position),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: animateBars ? barHeight(for: item.entry.points) : 20)
                            .overlay(
                                VStack {
                                    Text("\(item.position + 1)")
                                        .padding(.top, 7)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(item.position == 2 ? Color(hex: "#B1E902") : .white)
                                    
                                    Spacer()
                                   
                                    // Nombre del país
                                    Text(item.entry.country)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.bottom, 25)
                                }
                            )
                            .shadow(color: barColors(for: item.position)[0].opacity(0.5), radius: 8, y: 4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            // Texto descriptivo
            VStack(spacing: 4) {
                Text("Equipos liderando el podio")
                    .fontWeight(.medium)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                
                Text("¡Suma puntos para México completando los desafíos diarios!")
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            
            // Botón para ver más
            Button(action: {
                print("Botón presionado")
            }) {
                HStack(spacing: 4) {
                    Text("Visualiza el puntaje de los demás equipos")
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#1738EA"))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateBars = true
            }
        }
    }
    
    // Calcular altura de la barra basada en puntos (min 60, max 180)
    private func barHeight(for points: Int) -> CGFloat {
        let minHeight: CGFloat = 80
        let maxHeight: CGFloat = 180
        let ratio = CGFloat(points) / CGFloat(maxPoints)
        return minHeight + (maxHeight - minHeight) * ratio
    }
    
    // Colores diferentes para cada posición
    private func barColors(for index: Int) -> [Color] {
        switch index {
        case 0: // Primer lugar - Dorado/Amarillo
            return [Color(hex: "#18257E"), Color(hex: "#4DD0E2")]
        case 1: // Segundo lugar - Azul FIFA
            return [Color(hex: "#18257E"), Color(hex: "#B189FC")]
        case 2: // Tercer lugar - Verde neón
            return [Color(hex: "#18257E"), Color(hex: "#2F4FFC")]
        default:
            return [Color.gray, Color.gray.opacity(0.7)]
        }
    }
    private func podiumOrder() -> [(entry: LeaderboardEntry, position: Int)] {
        let top3 = Array(entries.prefix(3))
        guard top3.count == 3 else {
            return top3.enumerated().map { (entry: $1, position: $0) }
        }
        
        // Orden del podio clásico: segundo (0), primero (1), tercero (2)
        return [
            (entry: top3[1], position: 1), // 2do lugar a la izquierda
            (entry: top3[0], position: 0), // 1er lugar en el centro
            (entry: top3[2], position: 2)  // 3er lugar a la derecha
        ]
    }
}

// MARK: - Full leaderboard con barras
struct LeaderboardFullView: View {
    let entries: [LeaderboardEntry]
    @State private var animateBars = false
    
    private var maxPoints: Int {
        entries.map { $0.points }.max() ?? 1
    }
    
    var body: some View {
        ZStack {
            Color("BackgroudColor").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 12) {
                            // Posición
                            Text("\(index + 1)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(positionColor(for: index))
                                .frame(width: 30)
                            
                            // Bandera
                            Text(entry.flagEmoji)
                                .font(.system(size: 32))
                            
                            // País y puntos
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.country)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                // Barra de progreso
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        // Fondo de la barra
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 12)
                                        
                                        // Barra de progreso
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "#1738EA"), Color(hex: "#B1E902")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: animateBars ? geo.size.width * CGFloat(entry.points) / CGFloat(maxPoints) : 0,
                                                height: 12
                                            )
                                    }
                                }
                                .frame(height: 12)
                            }
                            
                            // Puntos
                            Text("\(entry.points)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#B1E902"))
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondaryBackground.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    index < 3 ? positionColor(for: index).opacity(0.5) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateBars = true
            }
        }
    }
    
    private func positionColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(hex: "#FFD700") // Oro
        case 1: return Color(hex: "#C0C0C0") // Plata
        case 2: return Color(hex: "#CD7F32") // Bronce
        default: return Color.white
        }
    }
}




// MARK: - Post card
struct PostCardView: View {
    @State private var showCommentsSheet = false
    @State private var commentText = ""
    
    let post: PostModel
    let onLike: () -> Void
    let onAddComment: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(post.user.avatarName)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                
                VStack(alignment: .leading) {
                    Text(post.user.displayName).bold()
                    Text("@\(post.user.username) • \(post.user.country)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(post.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // ⬇️⬇️⬇️ CAMBIA ESTA PARTE ⬇️⬇️⬇️
            if let challengePhoto = post.challengePhoto {
                // Muestra la foto que tomó el usuario
                Image(uiImage: challengePhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 240)
                    .clipped()
                    .cornerRadius(8)
            } else {
                // Muestra imagen por defecto si no hay foto del desafío
                Image(post.businessImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 240)
                    .clipped()
                    .cornerRadius(8)
            }
            // ⬆️⬆️⬆️ HASTA AQUÍ ⬆️⬆️⬆️
            
            Text(post.businessName)
                .font(.subheadline)
                .bold()
            
            Text(post.text)
                .font(.body)
            
            HStack {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        Text("\(post.likes)")
                    }
                }
                
                Button(action: { showCommentsSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments.count)")
                    }
                }
                Spacer()
            }
            .buttonStyle(.plain)
            .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(radius: 1))
        .sheet(isPresented: $showCommentsSheet) {
            CommentsSheet(post: post, onAdd: { text in onAddComment(text) })
        }
    }
}// MARK: - Comments sheet
struct CommentsSheet: View {
    @Environment(\.dismiss) var dismiss
    let post: PostModel
    @State private var newComment: String = ""
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(post.comments) { c in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(c.user.avatarName)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                Text(c.user.displayName).bold()
                                Spacer()
                                Text(c.date, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Text(c.text)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        onAdd(newComment)
                        newComment = ""
                    }
                }
                .padding()
            }
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

