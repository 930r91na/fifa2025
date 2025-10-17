//
//  ProfileView.swift
//  fifa2025
//
//  Created by Georgina on 11/10/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userData: UserDataManager  // ✅ DIRECTO - SIN ViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 5) {
                    ProfileHeaderView(user: userData.user)  // ✅ DIRECTO
                    
                    GamificationStatsView(
                        points: userData.user.points,     // ✅ CAMBIA EN VIVO
                        streak: userData.user.streak
                    )
                    
                    CompletedChallengesView(challenges: userData.user.completedChallenges)
                    
                    RecentActivityView(visits: userData.user.recentVisits(limit: 2))
                }
                .padding()
            }
            .background(Color("BackgroudColor"))
            .onAppear {
                print("🔍 Profile: \(userData.user.points) pts")  // DEBUG
            }
        }
    }
}

// MARK: - Subviews (TODO IGUAL)
struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("FWC26")
                    .font(.title.weight(.heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom,10)
                
                Text("Perfil")
                    .font(Font.theme.largeTitle)
                    .foregroundColor(Color.primaryText)
                    .padding(.top,1)
                    .padding(.leading, 5)
                
                HStack(alignment: .center) {
                    Image("user_local")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                        .padding(.trailing, 5)
                    
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(Font.theme.largeTitle)
                            .foregroundColor(Color.primaryText)
                        
                        Text("Supporting: \(user.teamPreference)")
                            .foregroundColor(Color.secondaryText)
                        
                        Text("🇲🇽")
                            .font(.system(size: 15))
                    }
                    
                    Spacer()
                }
                .font(Font.theme.subheadline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondaryBackground.opacity(0.5))
                .cornerRadius(16)
            }
            Spacer()
        }
    }
}

struct GamificationStatsView: View {
    let points: Int
    let streak: Int
    
    var body: some View {
        HStack {
            StatCard(title: "Total Points", value: "\(points) pts", icon: "star.fill", color: Color.fifaCompLime)
            StatCard(title: "Current Streak", value: "\(streak) Days", icon: "flame.fill", color: Color.fifaCompRed)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
                Spacer()
            }
            Text(value)
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct RecentActivityView: View {
    let visits: [Visit]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
                .padding(.horizontal)
            
            ForEach(visits) { visit in
                VisitRow(visit: visit)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct VisitRow: View {
    let visit: Visit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(visit.location.name)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                Spacer()
                Text(visit.date, style: .date)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
            }
            
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= visit.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
            
            if let comment = visit.comment {
                Text("\"\(comment)\"")
                    .font(Font.theme.body)
                    .italic()
                    .foregroundColor(Color.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CompletedChallengesView: View {
    let challenges: [Challenge]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Completed Challenges")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
                .padding(.horizontal)
            
            ForEach(challenges) { challenge in
                ChallengeRow(challenge: challenge)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct ChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Color.fifaCompGreen)
            
            VStack(alignment: .leading) {
                Text(challenge.title)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                Text(challenge.description)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
            }
            
            Spacer()
            
            Text("+\(challenge.pointsAwarded) pts")
                .font(Font.theme.subheadline)
                .foregroundColor(Color.fifaCompLime)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserDataManager())
}
