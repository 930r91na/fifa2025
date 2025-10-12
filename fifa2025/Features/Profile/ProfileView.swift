//
//  ProfileView.swift
//  fifa2025
//
//  Created by Georgina on 11/10/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderView(user: viewModel.user)
                    
                    GamificationStatsView(points: viewModel.user.points, streak: viewModel.user.streak)
                    
                    RecentActivityView(visits: viewModel.user.recentVisits(limit: 3))
                    
                    CompletedChallengesView(challenges: viewModel.user.completedChallenges)
                }
                .padding()
            }
            .background(Color.theme.background)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subviews for ProfileView

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        HStack {
            Image(systemName: user.profileImageName)
                .font(.system(size: 60))
                .foregroundColor(Color.theme.fifaAqua)
            
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(Font.theme.largeTitle)
                    .foregroundColor(Color.theme.primaryText)
                
                HStack {
                    Image(systemName: "flag.fill")
                    Text("Supporting: \(user.teamPreference)")
                }
                .font(Font.theme.subheadline)
                .foregroundColor(Color.theme.secondaryText)
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
            StatCard(title: "Total Points", value: "\(points) pts", icon: "star.fill", color: Color.theme.fifaLime)
            StatCard(title: "Current Streak", value: "\(streak) Days", icon: "flame.fill", color: Color.theme.fifaRed)
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
                    .foregroundColor(Color.theme.secondaryText)
                Spacer()
            }
            Text(value)
                .font(Font.theme.headline)
                .foregroundColor(Color.theme.primaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.theme.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct RecentActivityView: View {
    let visits: [Visit]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(Font.theme.headline)
                .foregroundColor(Color.theme.primaryText)
                .padding(.horizontal)
            
            ForEach(visits) { visit in
                VisitRow(visit: visit)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground.opacity(0.5))
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
                    .foregroundColor(Color.theme.primaryText)
                Spacer()
                Text(visit.date, style: .date)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.theme.secondaryText)
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
                    .foregroundColor(Color.theme.secondaryText)
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
                .foregroundColor(Color.theme.primaryText)
                .padding(.horizontal)
            
            ForEach(challenges) { challenge in
                ChallengeRow(challenge: challenge)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct ChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Color.theme.fifaGreen)
            
            VStack(alignment: .leading) {
                Text(challenge.title)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.theme.primaryText)
                Text(challenge.description)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.theme.secondaryText)
            }
            
            Spacer()
            
            Text("+\(challenge.pointsAwarded) pts")
                .font(Font.theme.subheadline)
                .foregroundColor(Color.theme.fifaLime)
        }
        .padding(.vertical, 8)
    }
}


#Preview {
    ProfileView()
}
