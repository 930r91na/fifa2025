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
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#") 
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
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
