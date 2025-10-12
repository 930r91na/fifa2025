//
//  DailyChallenge.swift
//  fifa2025
//
//  Created by Martha Heredia Andrade on 12/10/25.
//


import SwiftUI
struct ChallengeCard: View {
    let challenge: Challenge
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("+\(challenge.pointsAwarded) puntos")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .padding(.trailing, 118)
                .padding(.top, 10)
                .padding(.bottom, -15)
            
            Text(challenge.title)
                .font(Font.theme.subheadline)
                .foregroundColor(Color.primaryText)
                .padding(.top, 2)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 15)
 
   
            
           
         
            
            Button(action: {
                            if !challenge.isCompleted {
                                onComplete()
                            }
                        }) {
                            Text(challenge.isCompleted ? "¡Completado!" : "Intenta la experiencia!")
                                .font(.system(size: 13))
                                .fontWeight(.medium)
                                .foregroundColor(challenge.isCompleted ? Color(hex: "#10154F") : Color(.white))
                                .multilineTextAlignment(.center)
                                .frame(width: 180)
                                .padding(.vertical, 12)
                                .background(challenge.isCompleted ? Color(hex: "#B1E902") : Color(hex: "#18257E"))
                                .cornerRadius(10)
                        }
                        .disabled(challenge.isCompleted)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 20)
                    .padding(.leading, 30)
                    .frame(width: 240, height: 180)
                    .background(Color(hex: "#2F4FFC"))
                    .cornerRadius(18)
                }
            }



struct PointsAnimationView: View {
    let points: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#B1E902"))
            
            Text("+\(points) puntos")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#B1E902"))
            
            Text("¡Desafío completado!")
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .shadow(color: Color(hex: "#B1E902").opacity(0.5), radius: 20)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                offset = -20
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(1.5)) {
                opacity = 0
                offset = -40
            }
        }
    }
}
