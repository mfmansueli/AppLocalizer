//
//  IndexDataSection.swift
//  AppLocalizer
//

import SwiftUI

/// How fresh the index data is, with “Update Index Data”.
struct IndexDataSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        InspectorSection(.indexData, in: model) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(PriceIndexSource.allCases) { source in
                    if let index = model.index(source) {
                        HStack(spacing: Spacing.xSmall) {
                            Text(source.name).font(.callout)
                            Spacer(minLength: Spacing.xSmall)
                            Text(index.edition.label)
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                                .lineLimit(1)
                            if index.edition.isStale(asOf: .now) {
                                Pill(text: String(localized: "Older than a year"), style: .warning)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                Text(snapshotLine(model.snapshot))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Update Index Data") { model.updateIndexData() }
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("pricing.updateIndexData")
                if let message = model.updateMessage {
                    Text(message)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func snapshotLine(_ snapshot: PriceIndexSnapshot) -> String {
        let date = PricingText.date(snapshot.snapshotDate)
        let line = String(localized: "Bundled snapshot from \(date) · works offline")
        return snapshot.isApproximate ? line + String(localized: " · approximate") : line
    }
}
