//
//  OnboardingView.swift
//  fifa2025
//
//  Created by Georgina on 12/10/25.
//

import SwiftUI
internal import EventKit

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var selectedTab = 0
    @State private var selectedTeam: String?
    @State private var selectedInterests = Set<LocationType>()

    var body: some View {
        TabView(selection: $selectedTab) {
            WelcomeStepView(selectedTab: $selectedTab)
                .tag(0)
            
            TeamSelectionStepView(selectedTab: $selectedTab, selectedTeam: $selectedTeam)
                .tag(1)
            
            InterestSelectionStepView(selectedTab: $selectedTab, selectedInterests: $selectedInterests)
                .tag(2)
            
            PermissionsStepView(
                hasCompletedOnboarding: $hasCompletedOnboarding,
                selectedTeam: selectedTeam,
                selectedInterests: selectedInterests
            )
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(Color("BackgroudColor").ignoresSafeArea())
    }
}


struct TeamSelectionStepView: View {
    @Binding var selectedTab: Int
    @Binding var selectedTeam: String?

    // For a real app, this would come from a data source
    let teams = ["Mexico", "USA", "Canada", "Brazil", "Argentina", "Germany"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Who are you cheering for?")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)

            Text("This helps us tailor some fun surprises for you!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
                .padding(.bottom, 20)

            // A real implementation would have flags/logos. For now, text buttons are fine.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(teams, id: \.self) { team in
                    Button(action: {
                        selectedTeam = team
                        withAnimation {
                            selectedTab = 2
                        }
                    }) {
                        Text(team)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondaryBackground.opacity(0.5))
                            .cornerRadius(10)
                            .foregroundColor(Color.primaryText)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()

            Button("I'm just exploring") {
                 withAnimation {
                    selectedTab = 2
                }
            }
            .font(Font.theme.body)
            .foregroundColor(.secondaryText)
            .padding(.bottom, 50)
        }
        .padding(.top, 50)
    }
}

struct InterestSelectionStepView: View {
    @Binding var selectedTab: Int
    @Binding var selectedInterests: Set<LocationType>
    
    let interests: [LocationType] = LocationType.allCases

    var body: some View {
        VStack(spacing: 20) {
            Text("What are you excited to see?")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
            
            Text("Choose one or more. We'll find the best spots for you.")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
                .padding(.bottom, 20)

            ForEach(interests) { interest in
                InterestButton(
                    interest: interest,
                    isSelected: selectedInterests.contains(interest)
                ) {
                    if selectedInterests.contains(interest) {
                        selectedInterests.remove(interest)
                    } else {
                        selectedInterests.insert(interest)
                    }
                }
            }
            
            Spacer()

            Button(action: {
                withAnimation {
                    selectedTab = 3
                }
            }) {
                Text("Continue")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mainButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .padding()
        .padding(.top, 50)
    }
}

struct InterestButton: View {
    let interest: LocationType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: interest.sfSymbol)
                Text(interest.type)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.fifaCompLime)
                }
            }
            .font(Font.theme.subheadline)
            .padding()
            .background(isSelected ? Color.fifaCompPurple.opacity(0.4) : Color.secondaryBackground.opacity(0.5))
            .cornerRadius(10)
            .foregroundColor(Color.primaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.fifaCompPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}


struct PermissionsStepView: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @Binding var hasCompletedOnboarding: Bool
    
    // We'll use the existing managers
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var locationManager = LocationManager()
    
    let selectedTeam: String?
    let selectedInterests: Set<LocationType>

    var body: some View {
        VStack(spacing: 30) {
            Text("One last step!")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
            
            // Location Permission Explanation
            PermissionExplanationView(
                iconName: "location.fill",
                title: "Find Spots Near You",
                description: "Allow location access so we can show you hidden gems just around the corner.",
                isGranted: locationManager.isAuthorized()
            ) {
                locationManager.requestPermission()
            }
            
            // Calendar Permission Explanation
            PermissionExplanationView(
                iconName: "calendar",
                title: "Fit Fun Into Your Schedule",
                description: "Allow calendar access to get smart suggestions for your free time during match days.",
                isGranted: calendarManager.authorizationStatus == .fullAccess
            ) {
                calendarManager.requestAccess()
            }
            
            Spacer()
            
            Button(action: {
                userDataManager.completeOnboarding(
                    team: selectedTeam,
                    interests: selectedInterests
                )
                hasCompletedOnboarding = true
            }) {
                Text("Finish Setup")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mainButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .padding()
        .padding(.top, 50)
    }
}

struct PermissionExplanationView: View {
    let iconName: String
    let title: String
    let description: String
    let isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .font(.title)
                .frame(width: 40)
                .foregroundColor(isGranted ? .fifaCompGreen : .fifaCompRed)

            VStack(alignment: .leading) {
                Text(title)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                Text(description)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
            }
            
            Spacer()
            
            if !isGranted {
                Button("Enable", action: onRequest)
                    .buttonStyle(.borderedProminent)
                    .tint(.fifaCompPurple)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(12)
    }
}
