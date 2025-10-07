//
//  Theme.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import Foundation
import SwiftUI

// MARK: - Color Theme
extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
    let secondaryBackground = Color("SecondaryBackgroundColor")
    let primaryText = Color("PrimaryTextColor")
    let secondaryText = Color.secondary
    let success = Color.green
    let warning = Color.orange
    let error = Color.red
}

// MARK: - Font Theme
extension Font {
    static let theme = FontTheme()
}

struct FontTheme {
    let largeTitle = Font.system(size: 34, weight: .bold)
    let headline = Font.system(size: 24, weight: .semibold)
    let subheadline = Font.system(size: 18, weight: .medium)
    let body = Font.system(size: 16, weight: .regular)
    let caption = Font.system(size: 12, weight: .regular)
}
