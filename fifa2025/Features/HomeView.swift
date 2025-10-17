//
//  HomeView.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.

import SwiftUI
internal import EventKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var communityVM: CommunityViewModel
    @EnvironmentObject var userData: UserDataManager
    

    @State private var showChallengePopup = false
    @State private var selectedChallenge: Challenge?
    @State private var challengeIndexToComplete: Int?
     
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroudColor").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HeaderGreetingView(name: "Óscar")
                        ScoreView(points: userData.user.points)
                        ExploreCityView(viewModel: viewModel)
                        
                        
                        DailyChallengeView(
                            communityVM: communityVM,
                            showChallengePopup: $showChallengePopup,
                            selectedChallenge: $selectedChallenge,
                            challengeIndexToComplete: $challengeIndexToComplete
                        )
                    }
                    .padding()
                }
                .blur(radius: showChallengePopup ? 3 : 0)  // ✅ Blur a todo el contenido
                

                if showChallengePopup, let challenge = selectedChallenge, let index = challengeIndexToComplete {
                    ChallengePopupView(
                        challenge: challenge,
                        onDismiss: {
                            showChallengePopup = false
                            selectedChallenge = nil
                            challengeIndexToComplete = nil
                        },
                        onComplete: { photo, review, rating, recommended in
                            // Notificar a DailyChallengeView que complete el challenge
                            NotificationCenter.default.post(
                                name: NSNotification.Name("CompleteChallenge"),
                                object: nil,
                                userInfo: [
                                    "index": index,
                                    "photo": photo,
                                    "review": review,
                                    "rating": rating,
                                    "recommended": recommended
                                ]
                            )
                            showChallengePopup = false
                            selectedChallenge = nil
                            challengeIndexToComplete = nil
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)  // ✅ Asegurar que esté por encima de todo
                }
            }
            .task {
                await viewModel.loadInitialData()
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

// MARK: - Subviews (sin cambios)
struct HeaderGreetingView: View {
    var name: String
    
    var body: some View {
        VStack {
            Text("FWC26")
                .font(.title.weight(.heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)
            
            Spacer()
            
            HStack {
                NavigationLink(destination: ProfileView()) { }
                Spacer()
                
                Text("Hola, \(name)")
                    .padding(.leading, 7)
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
        HStack(spacing: 0) {
            Image(systemName: "calendar")
                .padding(.top, -15)
                .padding(.leading, 6)
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
    
    private var progress: Double {
        Double(points % 1000) / 1000.0
    }
    
    private var placesNeeded: Int {
        let remaining = 1000 - (points % 1000)
        return max(1, remaining / 500)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tu puntuación")
                    .fontWeight(.medium)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 15))
                    Text("\(points) pts")
                }
            }
            .font(Font.theme.subheadline)
            .foregroundColor(Color.primaryText)
            
            ProgressView(value: progress)
                .tint(.white)
            
            Text("¡Visita dos lugares más para subir de nivel!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
            
            Button(action: {
                print("Botón presionado")
            }) {
                HStack(spacing: 4) {
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
            
            
            Text("No suggestions right now.")
                .font(Font.theme.body)
                .foregroundColor(Color.secondaryText)
            Text("Check back when you have more free time!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
           
        }
   
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

// ✅ DailyChallengeView MODIFICADO
struct DailyChallengeView: View {
    @State private var challenges: [Challenge] = MockData.challengesAvailable
    @State private var showPointsAnimation = false
    @State private var earnedPoints = 0
    @State private var totalPoints = 0
    
    @ObservedObject var communityVM: CommunityViewModel
    @EnvironmentObject var userData: UserDataManager
    
    // ✅ Bindings desde HomeView
    @Binding var showChallengePopup: Bool
    @Binding var selectedChallenge: Challenge?
    @Binding var challengeIndexToComplete: Int?
    
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
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                            ChallengeCard(
                                challenge: challenge,
                                onComplete: {
                                    selectedChallenge = challenge
                                    challengeIndexToComplete = index
                                    showChallengePopup = true
                                }
                            )
                        }
                    }
                }
                .frame(height: 200)
                
                Image("component1")
                    .resizable()
                    .frame(width: 350, height: 60)
            }
            .padding()
            .padding(.top, 20)
            .background(Color.secondaryBackground.opacity(0.5))
            .cornerRadius(16)
            
            if showPointsAnimation {
                PointsAnimationView(points: earnedPoints)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(3)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CompleteChallenge"))) { notification in
            guard let userInfo = notification.userInfo,
                  let index = userInfo["index"] as? Int,
                  let photo = userInfo["photo"] as? UIImage,
                  let review = userInfo["review"] as? String,
                  let rating = userInfo["rating"] as? Int,
                  let recommended = userInfo["recommended"] as? Bool else { return }
            
            completeChallenge(at: index, photo: photo, review: review, rating: rating, recommended: recommended)
        }
    }
    
    private func completeChallenge(at index: Int, photo: UIImage, review: String, rating: Int, recommended: Bool) {
        guard !challenges[index].isCompleted else { return }
        
        var challenge = challenges[index]
        challenge.isCompleted = true
        challenge.completionDate = Date()
        challenge.photoEvidence = photo
        challenge.review = review
        challenge.rating = rating
        challenge.recommended = recommended
        
        challenges[index] = challenge
        
        var updatedUser = userData.user
        updatedUser.points += challenge.pointsAwarded
        updatedUser.completedChallenges.append(challenge)
        userData.user = updatedUser
        
        communityVM.updateLeaderboard(for: userData.user.teamPreference, adding: challenge.pointsAwarded)
        
        communityVM.addChallengePost(
            challengeTitle: challenge.title,
            photo: photo,
            review: review,
            rating: rating,
            recommended: recommended
        )
        
        earnedPoints = challenge.pointsAwarded
        totalPoints += earnedPoints
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showPointsAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPointsAnimation = false
            }
        }
    }
}

#Preview {
    HomeView(communityVM: CommunityViewModel())
}
