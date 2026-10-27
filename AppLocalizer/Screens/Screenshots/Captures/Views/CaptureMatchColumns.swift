//
//  CaptureMatchColumns.swift
//  AppLocalizer
//

import SwiftUI

/// The matching table's column titles and widths, shared with its rows.
struct CaptureMatchColumns: View {
    static let locale: CGFloat = 280
    static let display: CGFloat = 110
    static let slot: CGFloat = 50
    static let status: CGFloat = 24

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Text("File").frame(maxWidth: .infinity, alignment: .leading)
            Text("Locale").frame(width: Self.locale, alignment: .leading)
            Text("Display type").frame(width: Self.display, alignment: .leading)
            Text("Slot").frame(width: Self.slot, alignment: .leading)
            Color.clear.frame(width: Self.status, height: 1)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.label2)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
        .background(Palette.content)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .combine)
    }
}
