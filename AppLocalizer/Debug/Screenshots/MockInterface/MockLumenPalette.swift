//
//  MockLumenPalette.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The sample app's own colors. They belong to the mock interface, not to
/// AppLocalizer's design system.
enum MockLumenPalette {
    static let background = Color(red: 0.957, green: 0.957, blue: 0.973)
    static let card = Color.white
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let secondary = Color(red: 0.55, green: 0.55, blue: 0.6)
    static let accent = Color(red: 0.36, green: 0.33, blue: 0.91)
    static let accentSoft = Color(red: 0.36, green: 0.33, blue: 0.91).opacity(0.14)
    static let placeholder = Color(red: 0.86, green: 0.86, blue: 0.9)
    static let peach = LinearGradient(
        colors: [Color(red: 0.98, green: 0.7, blue: 0.55), Color(red: 0.93, green: 0.5, blue: 0.4)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let teal = LinearGradient(
        colors: [Color(red: 0.55, green: 0.8, blue: 0.72), Color(red: 0.3, green: 0.6, blue: 0.55)],
        startPoint: .top,
        endPoint: .bottom
    )
}
#endif
