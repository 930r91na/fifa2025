//
//  SuggestionCardView.swift
//  fifa2025
//
//  Created by Georgina on 09/10/25.
//

import SwiftUI

struct SuggestionCard: View {
    let suggestion: ItinerarySuggestion
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 6) {
            // Image with overlay
            ZStack(alignment: .top) {
                Image(suggestion.location.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 380)
                    .clipped()
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.3), Color.clear, Color.black.opacity(0.4)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Time Badge
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                    Text(suggestion.freeTimeSlot.start, style: .time)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
                .padding(.top, 16)
                
                // Location Info
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    Text(suggestion.location.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 13))
                            Text("\(String(format: "%.1f", suggestion.travelTime / 60)) min a pie")
                                .font(.system(size: 14, weight: .medium))
                        }
                        
                        Text(suggestion.location.type.type)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(12)
                    }
                    .foregroundColor(.white)
                }
                .padding(20)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 380)
            
            HStack(spacing: 10) {
                Button(action: {
                    print("Ver en mapa - \(suggestion.location.name)")
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16))
                        Text("Ver en mapa")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2F4FFC"))
                    .cornerRadius(14)
                }
                
                Button(action: {
                    viewModel.scheduleSuggestion(suggestion)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16))
                        Text("Agendar")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2F4FFC"))
                    .cornerRadius(14)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
        }
        .cornerRadius(24)
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
    // Add an optional action closure
    var action: (() -> Void)? = nil
    
    var body: some View {
        // Use the provided action
        Button(action: { action?() }) {
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
