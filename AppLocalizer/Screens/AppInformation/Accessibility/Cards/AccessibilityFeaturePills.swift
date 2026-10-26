//
//  AccessibilityFeaturePills.swift
//  AppLocalizer
//

import SwiftUI

/// The declared features as compact pills; blue for those that aren't on
/// the product page yet.
struct AccessibilityFeaturePills: View {
    let features: [AccessibilityFeature]
    let unpublished: Set<AccessibilityFeature>

    var body: some View {
        FlowLayout(spacing: Spacing.xxSmall, lineSpacing: Spacing.xxSmall) {
            ForEach(features) { feature in
                Pill(text: feature.name, style: unpublished.contains(feature) ? .accent : .neutral)
                    .accessibilityLabel(Text(unpublished.contains(feature) ? "\(feature.name), not published yet" : feature.name))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Features"))
    }
}

#Preview {
    AccessibilityFeaturePills(features: AccessibilityFeature.allCases, unpublished: [.reducedMotion])
        .frame(width: 320)
        .padding()
}
