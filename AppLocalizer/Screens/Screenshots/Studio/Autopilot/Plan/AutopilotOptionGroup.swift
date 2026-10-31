//
//  AutopilotOptionGroup.swift
//  AppLocalizer
//

import SwiftUI

/// A titled box of plan options: Devices, Languages, Simulator, Design and
/// checkpoints.
struct AutopilotOptionGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(title).font(.headline)
            content()
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
    }
}
