//
//  GuidedStepTitle.swift
//  AppLocalizer
//

import SwiftUI

/// A step's question and the line under it: "What should Autopilot
/// make?".
struct GuidedStepTitle: View {
    let title: String
    let subtitle: String
    var identifier = "autopilot.guided.title"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.tiny) {
            Text(title)
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(identifier)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
