//
//  SuggestionCardView.swift
//  fifa2025
//
//  Created by Georgina on 09/10/25.
//

import SwiftUI

struct SuggestionCardView: View {
    let suggestion: ItinerarySuggestion
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Card Background Image
            Image(suggestion.location.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 500) // Adjust height as needed
            
            // Gradient overlay for text readability
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 250)
            }
            
            // MARK: - Card Content
            VStack(alignment: .leading, spacing: 12) {
                Text(suggestion.freeTimeSlot.start, style: .time)
                    .font(Font.theme.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.4))
                    .cornerRadius(20)

                Text(suggestion.location.name)
                    .font(Font.theme.largeTitle)
                    .foregroundColor(Color.theme.primaryText)
                
                HStack {
                    InfoPill(text: "\(Int(suggestion.travelTime / 60)) min a pie")
                    InfoPill(text: suggestion.location.type.type)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    ActionButton(title: "Ver en mapa", icon: "mappin.and.ellipse")
                    ActionButton(title: "Agendar", icon: "calendar.badge.plus", isPrimary: true)
                }
            }
            .padding(24)
            .foregroundColor(.white)
        }
        .frame(height: 500) // Match the image frame height
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}


// MARK: - Subviews for SuggestionCardView

struct InfoPill: View {
    let text: LocalizedStringKey
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.2))
            .cornerRadius(20)
    }
}

struct ActionButton: View {
    let title: LocalizedStringKey
    let icon: String
    var isPrimary: Bool = false
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.footnote.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPrimary ? Color("MainButtonColor") : .white.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}
