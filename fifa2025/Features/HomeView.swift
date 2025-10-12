//
//  HomeView.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.

import SwiftUI
internal import EventKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroudColor").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                           
                        HeaderGreetingView(name: "Juan")
                        
                        ScoreView(points: 1250)
                        
                        ExploreCityView(viewModel: viewModel)
                        
                        DailyChallengeView()
                    }
                    .padding()
                }
            }
            .onAppear {
                viewModel.checkAndRequestPermissionsIfNeeded()
            }
             .alert("Calendar Update", isPresented: $viewModel.showScheduleAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.scheduleAlertMessage)
            }
        }

    }
}

// MARK: - Subviews for HomeView
struct HeaderGreetingView: View {
    var name: String
    
    var body: some View {
        VStack {
            Text("FWC26")
                .font(.title.weight(.heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom,10)
                
            
            Spacer()
            
            HStack {
                NavigationLink(destination: ProfileView()) {
                     Image(systemName: "person.crop.circle")
                         .font(.largeTitle)
                         .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Hola, \(name)")
                    .padding(.leading, 17)
                    .font(Font.theme.headline)
                    .foregroundColor(Color.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                HStack(spacing: 1) {
                    Image(systemName: "mappin")
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                    Text("Ciudad de México")
                        .font(Font.theme.caption)
                        .foregroundColor(Color.secondaryText)
                }
            }
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack (spacing:0){
            Image(systemName: "calendar")
                .padding(.top, -15)
                .padding(.leading,6)
               
                .font(.system(size: 25))
                .foregroundColor(.white)
            
            
            VStack(alignment: .leading) {
                
                Text("Explora la ciudad")
                    .padding(.top, 23)
                    .font(Font.theme.headline)
                    
                    .foregroundColor(Color.primaryText)
                
                Text("Te recomendamos los mejores momentos de acuerdo a tu calendario.")
                    .font(Font.theme.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 5)
                
                
                    .foregroundColor(.white)
            }
            .padding(.leading, 10)
            
            
        }
        
    }
    
}

struct ScoreView: View {
    var points: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tu puntuación")
                    .fontWeight(.medium)
                Spacer()
                
                HStack (spacing: 2){
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 15))
                    Text("\(points) pts")
                    
                }
                
                
                
            }
            .font(Font.theme.subheadline)
            .foregroundColor(Color.primaryText)
            
           
            ProgressView(value: 0.75)
                .tint(.white)
            
            Text("¡Visita dos lugares más para subir de nivel!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
            Button(action: {
                print("Botón presionado")
            }) {
                HStack (spacing:4) {
                    Text("Descubre cómo los demás están ganando puntos")
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
    }
}


struct NoSuggestionsView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("No suggestions right now.")
                .font(Font.theme.body)
                .foregroundColor(Color.secondaryText)
            Text("Check back when you have more free time!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
            Spacer()
        }
        .padding()
    }
}

struct CalendarAccessPromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Get personalized suggestions!")
                .font(Font.theme.headline)
            Text("Enable calendar access in your iPhone's Settings to see local recommendations.")
                .font(Font.theme.body)
                .foregroundColor(Color.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(30)
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.leading, 15)
    }
}


struct DailyChallengeView: View {
    @State private var challenges: [Challenge] = MockData.challengesAvailable;
    
    @State private var showPointsAnimation = false
    @State private var earnedPoints = 0
    @State private var totalPoints = 0
    
    var completedChallenges: Int {
        challenges.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    VStack(spacing: 6) {
                        Text("Desafíos del día")
                            .font(Font.theme.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Completa los desafíos para acumular puntos y compite para que tu equipo quede en podio")
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    
                    
                    Text("\(completedChallenges)/\(challenges.count)")
                        .font(Font.theme.caption)
                }
                .foregroundColor(Color.primaryText)
                .padding(.bottom, 10)
                
                
                
                // ScrollView horizontal para las tarjetas
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                            ChallengeCard(
                                challenge: challenge,
                                onComplete: {
                                    completeChallenge(at: index)
                                }
                            )
                        }
                    }
                }
                .frame(height: 200)
                
                Image("component1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 60)
            }
            .padding()
            .background(Color.secondaryBackground.opacity(0.5))
            .cornerRadius(16)
            
            // Animación de puntos ganados
            if showPointsAnimation {
                PointsAnimationView(points: earnedPoints)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }
    
    private func completeChallenge(at index: Int) {
        guard !challenges[index].isCompleted else { return }
        
        // Obtener puntos ganados
        earnedPoints = challenges[index].pointsAwarded
        totalPoints += earnedPoints
        
        // Mostrar animación
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showPointsAnimation = true
        }
        
        // Ocultar animación después de 2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPointsAnimation = false
            }
        }
    }
}


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


#Preview {
    HomeView()
}
