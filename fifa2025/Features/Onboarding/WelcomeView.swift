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
            
            Text("Bienvenido a\nTurismo Local WC26")
                .font(Font.theme.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Descubre lugares locales auténticos y apoya a la comunidad, directamente desde tu bolsillo.")
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
                Text("Comenzar")
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
