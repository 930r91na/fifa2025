//
//  ContentView.swift
//  fifa2025
//
//  Created by Georgina on 30/09/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var receivedCard: WorldCupCard?
    let userDataManager: UserDataManager
    let communityVM: CommunityViewModel  
    

    
    var body: some View {
        TabView {
            HomeView(communityVM: communityVM)
                .tabItem {
                    Label("Inicio", systemImage: "soccerball")
                }
                .environmentObject(userDataManager)
            
            CommunityView(vm: communityVM)
                .tabItem {
                    Label("Equipos", systemImage: "person.3.fill")
                }
                .environmentObject(userDataManager)
            
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
                .environmentObject(userDataManager)
            
            MapView()
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }
                .environmentObject(userDataManager)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(userDataManager)
        }
        .sheet(item: $receivedCard) { card in
            ReceivedCardView(card: card)
        }
        .environmentObject(userDataManager)
        .environmentObject(communityVM)
    }
}
