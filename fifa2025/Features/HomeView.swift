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
                // Use the theme background color
                Color("BackgroudColor").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HeaderGreetingView(name: "Geo")
                                    
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
        HStack {
            Text("FWC26")
                .font(.title.weight(.heavy))
                .foregroundColor(.white)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Hola, \(name)")
                    .font(Font.theme.headline)
                    .foregroundColor(Color.theme.primaryText)
                Text("Ciudad de México")
                    .font(Font.theme.caption)
                    .foregroundColor(Color.theme.secondaryText)
            }
        }
    }
}


struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "calendar")
            VStack(alignment: .leading) {
                Text("Explora la ciudad")
                    .font(Font.theme.headline)
                    .foregroundColor(Color.theme.primaryText)
                
                Text("Te recomendamos los mejores momentos de acuerdo a tu calendario.")
                    .font(Font.theme.caption)
                    .foregroundColor(Color.theme.secondaryText)
            }
        }
    }
}

struct ScoreView: View {
    var points: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tu puntuación")
                Spacer()
                Image(systemName: "trophy.fill")
                Text("\(points) pts")
            }
            .font(Font.theme.subheadline)
            .foregroundColor(Color.theme.primaryText)
            
            // Placeholder for progress bar
            ProgressView(value: 0.75)
                .tint(Color.theme.fifaLime)
            
            Text("¡Visita dos lugares más para subir de nivel!")
                .font(Font.theme.caption)
                .foregroundColor(Color.theme.secondaryText)
        }
        .padding()
        .background(Color.theme.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}


struct NoSuggestionsView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("No suggestions right now.")
                .font(Font.theme.body)
                .foregroundColor(Color.theme.secondaryText)
            Text("Check back when you have more free time!")
                .font(Font.theme.caption)
                .foregroundColor(Color.theme.secondaryText)
            Spacer()
        }
        .padding()
    }
}

struct CalendarAccessPromptView: View {
    var body: some View {
        // This view can be simplified or enhanced, as it no longer needs a button.
        // It now serves as an informational placeholder.
        VStack(spacing: 16) {
            Spacer()
            Text("Get personalized suggestions!")
                .font(Font.theme.headline)
            Text("Enable calendar access in your iPhone's Settings to see local recommendations.")
                .font(Font.theme.body)
                .foregroundColor(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(30)
        .background(Color.theme.secondaryBackground.opacity(0.5))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}


struct ExploreCityView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HeaderView() // Re-using the header from the previous step

            // This frame modifier is the key to fixing the size issue
            Group {
                if viewModel.calendarAuthorizationStatus == .fullAccess {
                    if viewModel.suggestions.isEmpty {
                        NoSuggestionsView()
                            .frame(height: 300) // Give a consistent height
                    } else {
                        SuggestionCarouselView(suggestions: viewModel.suggestions, viewModel: viewModel)
                    }
                } else {
                    CalendarAccessPromptView()
                        .frame(height: 300) // Give a consistent height
                }
            }
            .frame(height: 500) // **This is the fix to control the carousel's height**
        }
    }
}


struct DailyChallengeView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Desafío del día")
                    .font(Font.theme.subheadline)
                Spacer()
                Text("1/3")
                    .font(Font.theme.caption)
            }
            .foregroundColor(Color.theme.primaryText)
            
            Text("Visitar un restaurante local")
                .font(Font.theme.headline)
                .foregroundColor(Color.theme.primaryText)
                .padding(.vertical, 8)
            
            Button(action: {}) {
                Text("Registrar y dejar reseña")
                    .font(.footnote.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("MainButtonColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}


#Preview {
    HomeView()
}
