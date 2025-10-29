//
//  ExploreCityView.swift
//  fifa2025
//
//  Created by Georgina on 12/10/25.
//


import SwiftUI

struct ExploreCityView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDraggingHorizontally: Bool? = nil

    var body: some View {
        ZStack {
            Color.secondaryBackground.opacity(0.5)
                .cornerRadius(16)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
            
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("Explora la ciudad")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                
                Text("Te recomendamos los mejores \n lugares de acuerdo a tu calendario.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 53)
                    .padding(.top, -10)
                    .fixedSize(horizontal: false, vertical: true)
                
                if viewModel.suggestions.isEmpty {
                    VStack {
                        Text("¡No hay sugerencias por ahora!")
                            .font(Font.theme.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.secondaryText)
                            .multilineTextAlignment(.center)
                           
                        Text("¡Vuelve más tarde cuando tengas un poco de tiempo libre!")
                            .font(Font.theme.caption)
                            .foregroundColor(Color.secondaryText.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, -55)
                    .frame(height: 530)
                    
                } else {
                    GeometryReader { geometry in
                        let cardWidth = geometry.size.width * 0.85
                        let peekAmount: CGFloat = 50
                        
                        ZStack {
                            ForEach(Array(viewModel.suggestions.enumerated()), id: \.offset) { index, suggestion in
                                let distance = CGFloat(index - currentIndex)
                                let offset = distance * (cardWidth - peekAmount) + dragOffset
                                let scale = getScale(for: index)
                                let opacity = getOpacity(for: index)
                                
                                SuggestionCard(suggestion: suggestion, viewModel: viewModel)
                                    .frame(width: cardWidth)
                                    .scaleEffect(scale)
                                    .opacity(opacity)
                                    .offset(x: offset)
                                    .zIndex(index == currentIndex ? 10 : Double(5 - abs(index - currentIndex)))
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 20)
                                .onChanged { value in
                                    if isDraggingHorizontally == nil {
                                        let horizontalAmount = abs(value.translation.width)
                                        let verticalAmount = abs(value.translation.height)
                                        isDraggingHorizontally = horizontalAmount > verticalAmount
                                    }
                                    
                                    if isDraggingHorizontally == true {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if isDraggingHorizontally == true {
                                        let threshold: CGFloat = 50
                                        
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if value.translation.width < -threshold && currentIndex < viewModel.suggestions.count - 1 {
                                                currentIndex += 1
                                            } else if value.translation.width > threshold && currentIndex > 0 {
                                                currentIndex -= 1
                                            }
                                            dragOffset = 0
                                        }
                                    }
                                    
                                    isDraggingHorizontally = nil
                                    dragOffset = 0
                                }
                        )
                    }
                    .padding(.top, -55)
                    .frame(height: 530)
                    .clipped()
                    
                    HStack(spacing: 12) {
                        ForEach(0..<viewModel.suggestions.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                                .animation(.easeInOut(duration: 0.3), value: currentIndex)
                        }
                    }
                    .padding(.top, -50)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(height: 600)
        .padding(.top, 30)
    }
    
    private func getScale(for index: Int) -> CGFloat {
        let distance = abs(currentIndex - index)
        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            return 0.85
        } else {
            return 0.7
        }
    }
    
    private func getOpacity(for index: Int) -> Double {
        let distance = abs(currentIndex - index)
        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            return 0.5
        } else {
            return 0.0
        }
    }
}


#Preview {
    ExploreCityView(viewModel: HomeViewModel())
        .environmentObject(UserDataManager.shared)
        .background(Color.black)
}
