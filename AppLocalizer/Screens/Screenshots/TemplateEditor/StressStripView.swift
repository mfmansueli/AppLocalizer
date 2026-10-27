//
//  StressStripView.swift
//  AppLocalizer
//

import SwiftUI

/// The same slot in the four locales that break layouts first, updating
/// as the template changes.
struct StressStripView: View {
    let model: TemplateEditorViewModel
    let cardWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stress strip")
                    .font(.headline)
                Text("Slot \(model.slot + 1) in the four locales that break layouts first. Updates as you edit.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .layoutPriority(1)
            }
            let columns = Array(repeating: GridItem(.fixed(cardWidth + 16), spacing: Spacing.medium), count: 2)
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.medium) {
                ForEach(model.strip) { entry in
                    StressStripCard(entry: entry, capture: model.captureImage(for: entry.preview), width: cardWidth)
                }
            }
        }
        .frame(width: 2 * (cardWidth + 16) + Spacing.medium, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.template.strip")
    }
}
