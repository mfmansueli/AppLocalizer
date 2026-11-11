//
//  PaywallStyle.swift
//  AppLocalizer
//

import SwiftUI

/// Pro's own colors: the indigo-to-purple of the paywall's left side, the
/// PRO chip and the toolbar's Pro button.
enum PaywallStyle {
    static let indigo = Color(red: 0x3B / 255, green: 0x2F / 255, blue: 0xC4 / 255)
    static let violet = Color(red: 0x6A / 255, green: 0x35 / 255, blue: 0xD0 / 255)
    static let purple = Color(red: 0x8A / 255, green: 0x3C / 255, blue: 0xD6 / 255)

    static let gradient = LinearGradient(
        colors: [Color(red: 0x4B / 255, green: 0x3B / 255, blue: 0xD6 / 255), purple], startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let paneGradient = LinearGradient(
        stops: [.init(color: indigo, location: 0), .init(color: violet, location: 0.55), .init(color: purple, location: 1)],
        startPoint: .top, endPoint: .bottom
    )

    static let sheetSize = CGSize(width: 840, height: 600)
    static let paneWidth: CGFloat = 320
}
