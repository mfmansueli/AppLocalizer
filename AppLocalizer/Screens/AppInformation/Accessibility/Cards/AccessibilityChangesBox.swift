//
//  AccessibilityChangesBox.swift
//  AppLocalizer
//

import SwiftUI

/// "Live now → after publishing": what a published declaration gains and
/// loses when the newer answer publishes.
struct AccessibilityChangesBox: View {
    let added: [AccessibilityFeature]
    let removed: [AccessibilityFeature]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text("LIVE NOW → AFTER PUBLISHING")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
            ForEach(added) { feature in
                line("+", feature.name)
                    .accessibilityLabel(Text("Adds \(feature.name)"))
            }
            ForEach(removed) { feature in
                line("−", feature.name)
                    .accessibilityLabel(Text("Removes \(feature.name)"))
            }
        }
        .padding(Spacing.small + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.accessibility.changes")
    }

    private func line(_ sign: String, _ name: String) -> some View {
        HStack(spacing: Spacing.small) {
            Text(sign)
                .monospaced()
                .frame(width: 8)
            Text(name)
        }
        .font(.caption)
        .accessibilityElement(children: .ignore)
    }
}

#Preview {
    AccessibilityChangesBox(added: [.reducedMotion], removed: [.captions])
        .frame(width: 320)
        .padding()
}
