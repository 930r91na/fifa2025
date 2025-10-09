//
//  ContentView.swift
//  fifa2025
//
//  Created by Georgina on 30/09/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            CommunityView()
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
