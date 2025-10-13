//
//  ContentView.swift
//  fifa2025
//
//  Created by Georgina on 30/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var communityVM = CommunityViewModel() 
    
    
    var body: some View {
        TabView {
            HomeView(communityVM: communityVM)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            CommunityView(vm: communityVM)
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
            
            AlbumView()
                .tabItem {
                    Label("Album", systemImage: "photo.stack.fill")
                }
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
