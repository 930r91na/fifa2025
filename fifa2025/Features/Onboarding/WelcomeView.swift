//
//  WelcomeView.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//

import SwiftUI

struct WelcomeStepView: View {
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Welcome to\nTurismo Local WC26")
                .font(Font.theme.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Discover authentic local spots and support the community, right from your pocket.")
                .font(Font.theme.subheadline)
                .foregroundColor(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    selectedTab = 1
                }
            }) {
                Text("Get Started")
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
    }
}


