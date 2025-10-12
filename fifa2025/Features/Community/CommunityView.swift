//
//  CommunityView.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import SwiftUI
import Combine

struct CommunityView: View {
    @StateObject private var vm = CommunityViewModel()
    private let localUser = UserModel(id: UUID(), username: "me_local", displayName: "You", avatarName: "user_local", country: "Mexico")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
            .navigationTitle("Community")
            .navigationDestination(for: [LeaderboardEntry].self) { entries in
                LeaderboardFullView(entries: entries)
            }
        }
    }
}

// MARK: - Leaderboard preview
struct LeaderboardPreviewView: View {
    let entries: [LeaderboardEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Countries")
                .font(.headline)
            
            HStack {
                ForEach(entries.prefix(3)) { e in
                    VStack {
                        if let flag = e.flagName {
                            Image(flag)
                                .resizable()
                                .frame(width: 48, height: 30)
                                .cornerRadius(4)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 48, height: 30)
                        }
                        Text(e.country)
                            .font(.caption2)
                        Text("\(e.points) pts")
                            .font(.caption2)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
        }
    }
}

// MARK: - Full leaderboard
struct LeaderboardFullView: View {
    let entries: [LeaderboardEntry]
    
    var body: some View {
        List {
            ForEach(entries) { e in
                HStack {
                    if let flag = e.flagName {
                        Image(flag)
                            .resizable()
                            .frame(width: 40, height: 26)
                            .cornerRadius(4)
                    }
                    VStack(alignment: .leading) {
                        Text(e.country)
                        Text("\(e.points) pts")
                            .font(.caption2)
                            .bold()
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Leaderboard")
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
            
            Image(post.businessImageName)
                .resizable()
                .scaledToFill()
                .frame(maxHeight: 240)
                .clipped()
                .cornerRadius(8)
            
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
}

// MARK: - Comments sheet
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

#Preview {
    CommunityView()
}
