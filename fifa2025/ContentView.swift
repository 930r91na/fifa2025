//
//  ContentView.swift
//  fifa2025
//
//  Created by Georgina on 30/09/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var receivedCard: WorldCupCard?
    let userDataManager: UserDataManager  // ← RECIBE AQUÍ
    let communityVM: CommunityViewModel   // ← RECIBE AQUÍ
    

    
    var body: some View {
        TabView {
            HomeView(communityVM: communityVM)  // Ya recibe communityVM ✅
                .tabItem {
                    Label("Inicio", systemImage: "soccerball")
                }
                .environmentObject(userDataManager)  // ← INYECTA A ESTA VISTA
            
            CommunityView(vm: communityVM)       // Ya recibe communityVM ✅
                .tabItem {
                    Label("Equipos", systemImage: "person.3.fill")
                }
                .environmentObject(userDataManager)  // ← INYECTA A ESTA VISTA
            
            AlbumView()
                .tabItem {
                    Label {
                        Text("Albúm")
                    } icon: {
                        Image("album")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 26, height: 26)
                    }
                }
                .environmentObject(userDataManager)  // ← INYECTA A ESTA VISTA
            
            MapView()
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }
                .environmentObject(userDataManager)  // ← INYECTA A ESTA VISTA
            
            ProfileView()                        // Recibirá via environmentObject
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(userDataManager)  // ← INYECTA A ESTA VISTA
        }
        .sheet(item: $receivedCard) { card in
            ReceivedCardView(card: card)
        }
        .environmentObject(userDataManager)  // ← GLOBAL POR SI ALGUNA SUBVISTA LO NECESITA
        .environmentObject(communityVM)      // ← GLOBAL POR SI ALGUNA SUBVISTA LO NECESITA
    }
}
