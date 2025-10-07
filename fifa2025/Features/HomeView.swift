//
//  HomeView.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//
import SwiftUI
internal import EventKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Suggestions for You")
                        .font(Font.theme.largeTitle)
                        .padding(.horizontal)
                    
                    if viewModel.calendarAuthorizationStatus != .fullAccess {
                        CalendarAccessPromptView(viewModel: viewModel)
                    } else if viewModel.suggestions.isEmpty {
                        Text("No suggestions right now. Check back when you have more free time!")
                            .font(Font.theme.body)
                            .foregroundColor(Color.theme.secondaryText)
                            .padding()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.suggestions) { suggestion in
                                    SuggestionCardView(suggestion: suggestion)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Home")
        }
    }
}

// MARK: - Subviews

struct SuggestionCardView: View {
    let suggestion: ItinerarySuggestion
    
    var body: some View {
        VStack(alignment: .leading) {
            // In a real app, you'd load an image from location.imageName
            Color.gray.opacity(0.3)
                .frame(height: 120)
                .overlay(
                    Image(systemName: suggestion.location.type.sfSymbol)
                        .font(.largeTitle)
                        .foregroundColor(Color.theme.accent)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(suggestion.location.name)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(1)
                
                Text(suggestion.reason)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.theme.secondaryText)
                
                HStack {
                    Image(systemName: "location.fill")
                    Text("\(Int(suggestion.travelTime / 60)) min drive")
                }
                .font(Font.theme.caption)
                .foregroundColor(Color.theme.accent)
            }
            .padding()
        }
        .background(Color.theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
        .frame(width: 220)
    }
}

struct CalendarAccessPromptView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Get personalized suggestions!")
                .font(Font.theme.headline)
            Text("Allow calendar access to find free time in your schedule for local adventures.")
                .font(Font.theme.body)
                .foregroundColor(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Grant Access") {
                viewModel.requestCalendarAccess()
            }
            .padding()
            .background(Color.theme.accent)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(30)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}


#Preview {
    HomeView()
}
