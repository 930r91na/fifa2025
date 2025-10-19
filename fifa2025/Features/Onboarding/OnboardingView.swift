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

    
    let teams = ["México", "EE. UU.", "Canadá", "Brasil", "Argentina", "Alemania"]


    var body: some View {
        VStack(spacing: 20) {
            Text("¿A quién estás apoyando?")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)

            Text("¡Esto nos ayuda a preparar algunas sorpresas divertidas para ti!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
                .padding(.bottom, 20)

        
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

            Button("Solo estoy explorando") {
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
        
            Text("¿Qué te emociona ver?")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)

            Text("Elige una o más opciones. Encontraremos los mejores lugares para ti.")
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
                Text("Continuar")
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
    

    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var locationManager = LocationManager()
    
    let selectedTeam: String?
    let selectedInterests: Set<LocationType>

    var body: some View {
        VStack(spacing: 30) {
            Text("¡Un último paso!")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)


            PermissionExplanationView(
                iconName: "location.fill",
                title: "Encuentra lugares cerca de ti",
                description: "Permite el acceso a tu ubicación para mostrarte joyas ocultas justo a la vuelta de la esquina.",
                isGranted: locationManager.isAuthorized()
            ) {
                locationManager.requestPermission()
            }

            
            PermissionExplanationView(
                iconName: "calendar",
                title: "Ajusta la diversión a tu horario",
                description: "Permite el acceso al calendario para recibir sugerencias inteligentes según tu tiempo libre durante los días de partido.",
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
                Text("Finalizar configuración")
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
                Button("Habilitar", action: onRequest)
                    .buttonStyle(.borderedProminent)
                    .tint(.fifaCompPurple)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(12)
    }
}
