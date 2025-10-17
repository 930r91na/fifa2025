//
//  SplashView.swift
//  fifa2025
//
//  Created by Martha Heredia Andrade on 17/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SplashView: View {
    @Binding var receivedCard: WorldCupCard?
    @ObservedObject var userDataManager: UserDataManager
    @ObservedObject var communityVM: CommunityViewModel
    
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        if isActive {
            ContentView(
                receivedCard: $receivedCard,
                userDataManager: userDataManager,
                communityVM: communityVM
            )
        } else {
            ZStack {
                Color("BackgroudColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    
                }
            }
            .onAppear {
                // Animación del logo
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                // Rotación sutil
                withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                    rotationAngle = 360
                }
                
                // Transición a la app principal
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
