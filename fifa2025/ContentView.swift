//
//  ContentView.swift
//  fifa2025
//
//  Created by Georgina on 30/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var communityVM = CommunityViewModel() 
    @Binding var receivedCard: WorldCupCard?
    
    var body: some View {
        TabView {
            HomeView(communityVM: communityVM)
                .tabItem {
                    Label("Inicio", systemImage: "soccerball")
                }
            
            CommunityView(vm: communityVM)
                .tabItem {
                    Label("Equipos", systemImage: "person.3.fill")
                }
            
            AlbumView()
                .tabItem {
                    Label {
                        Text("Albúm")
                    } icon: {
                        Image("album")        // o usar un image system
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 26, height: 26)
                    }
                }
            
            MapView()
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }

        }
        .sheet(item: $receivedCard) { card in ReceivedCardView(card: card)
        }
    }
}
