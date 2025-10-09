//
//  SuggestionsCarouselView.swift
//  fifa2025
//
//  Created by Georgina on 09/10/25.
//

import SwiftUI

struct SuggestionCarouselView: View {
    let suggestions: [ItinerarySuggestion]
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            // MARK: - Background Image Carousel
            TabView(selection: $currentIndex) {
                ForEach(suggestions.indices, id: \.self) { index in
                    Image(suggestions[index].location.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .blur(radius: 15, opaque: true)
            .opacity(0.6)
            
            // Overlay to darken the background
            Rectangle()
                .fill(.black.opacity(0.4))

            // MARK: - Foreground Card Carousel
            TabView(selection: $currentIndex) {
                ForEach(suggestions.indices, id: \.self) { index in
                    SuggestionCardView(suggestion: suggestions[index])
                        .tag(index)
                        .padding(.horizontal, 40) // Creates space for background to peek through
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea()
    }
}

