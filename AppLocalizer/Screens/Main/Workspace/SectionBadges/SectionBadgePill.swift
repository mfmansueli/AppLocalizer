//
//  SectionBadgePill.swift
//  AppLocalizer
//

import SwiftUI

/// The count on a section in the toolbar's picker.
struct SectionBadgePill: View {
    static let fontSize: CGFloat = 10
    private static let height: CGFloat = 16
    private static let horizontalPadding: CGFloat = 5

    let text: String
    let width: CGFloat

    /// A single digit makes a circle; more digits, a capsule.
    static func width(textWidth: CGFloat) -> CGFloat {
        max(height, textWidth + horizontalPadding * 2)
    }

    var body: some View {
        Text(text)
            .font(.system(size: Self.fontSize, weight: .semibold))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Palette.suggestionBadgeText)
            .frame(width: width, height: Self.height)
            .background(Palette.suggestionBadge, in: Capsule())
    }
}
