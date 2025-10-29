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
    @State private var selectedArchetype: UserArchetype?
    @State private var selectedInterests = Set<LocationType>()

    var body: some View {
        TabView(selection: $selectedTab) {
            WelcomeStepView(selectedTab: $selectedTab)
                .tag(0)
            
            ArchetypeSelectionView(
                selectedTab: $selectedTab,
                selectedArchetype: $selectedArchetype,
                selectedInterests: $selectedInterests
            )
                .tag(1)
            
            TeamSelectionStepView(selectedTab: $selectedTab, selectedTeam: $selectedTeam)
                .tag(2)
            
            InterestSelectionStepView(selectedTab: $selectedTab, selectedInterests: $selectedInterests)
                .tag(3)
            
            PermissionsStepView(
                hasCompletedOnboarding: $hasCompletedOnboarding,
                selectedTeam: selectedTeam,
                selectedArchetype: selectedArchetype,
                selectedInterests: selectedInterests
            )
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(Color("BackgroudColor").ignoresSafeArea())
    }
}

// MARK: - Archetype Selection
struct ArchetypeSelectionView: View {
    @Binding var selectedTab: Int
    @Binding var selectedArchetype: UserArchetype?
    @Binding var selectedInterests: Set<LocationType>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("¿Qué tipo de viajero eres?")
                    .font(Font.theme.headline)
                    .foregroundColor(Color.primaryText)
                    .padding(.top, 50)

                Text("Selecciona el perfil que mejor te describe")
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
                    .padding(.bottom, 10)

                ForEach(UserArchetype.allCases, id: \.self) { archetype in
                    ArchetypeCard(
                        archetype: archetype,
                        isSelected: selectedArchetype == archetype
                    ) {
                        selectedArchetype = archetype
                        selectedInterests = archetype.interests
                        
                        withAnimation {
                            selectedTab = 2
                        }
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal)
        }
    }
}

struct ArchetypeCard: View {
    let archetype: UserArchetype
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(archetype.displayName)
                    .font(Font.theme.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText)
                
                Text(archetype.description)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? Color.fifaCompPurple.opacity(0.3) : Color.secondaryBackground.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.fifaCompPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct TeamSelectionStepView: View {
    @Binding var selectedTab: Int
    @Binding var selectedTeam: String?
    
    let teams = ["México", "EE. UU.", "Canadá", "Brasil", "Argentina", "Alemania"]

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
                            selectedTab = 3
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
                    selectedTab = 3
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
            Text("Ajusta tus intereses")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)

            Text("Personaliza las sugerencias según tus preferencias")
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
                    selectedTab = 4
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
 
    
    let selectedTeam: String?
    let selectedArchetype: UserArchetype?
    let selectedInterests: Set<LocationType>

    var body: some View {
        VStack(spacing: 30) {
            Text("¡Un último paso!")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)

           // PermissionExplanationView(
             //   iconName: "location.fill",
              //  title: "Encuentra lugares cerca de ti",
           //     description: "Permite el acceso a tu ubicación para mostrarte joyas ocultas justo a la vuelta de la esquina.",
             //   isGranted: locationManager.isAuthorized()
          //  ) {
        //        locationManager.requestPermission()
         //   }
            
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
                // ✅ Compatibilidad con tu UserDataManager actual
                userDataManager.completeOnboarding(
                    team: selectedTeam,
                    archetype: selectedArchetype,
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
