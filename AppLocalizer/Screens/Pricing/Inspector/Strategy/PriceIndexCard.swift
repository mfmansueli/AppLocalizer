//
//  PriceIndexCard.swift
//  AppLocalizer
//

import SwiftUI

/// One price index to choose: who publishes it, which edition, how many
/// territories it covers, what it's good at, and whether it's stale.
struct PriceIndexCard: View {
    let source: PriceIndexSource
    let index: PriceIndex?
    let territoryCount: Int
    let isSelected: Bool
    let now: Date
    let onSelect: () -> Void
    let onImport: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Button(action: onSelect) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(source.name).font(.body.weight(.semibold))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                        if let index {
                            Text(index.coverageLabel(of: territoryCount))
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(index == nil)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            .accessibilityIdentifier("pricing.index.\(source.rawValue)")
            Text(source.summary)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 22)
            badges
                .padding(.leading, 22)
        }
        .padding(Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(isSelected ? Palette.accent : border, lineWidth: isSelected ? 2 : 0.5)
        }
    }

    private var border: Color { contrast == .increased ? Palette.separator2 : Palette.separator }

    private var subtitle: String {
        guard let index else { return source.publisher }
        return "\(index.publisher) · \(index.edition.label)"
    }

    private var badges: some View {
        HStack(spacing: Spacing.xSmall) {
            if let edition = index?.edition {
                if let newer = edition.newerEditionLabel {
                    Pill(text: newer, style: .accent)
                } else if edition.isStale(asOf: now) {
                    Pill(text: String(localized: "Older than a year"), style: .warning)
                }
            }
            if let url = source.sourceURL {
                Link(destination: url) {
                    Text("Source ↗")
                }
                .font(.caption)
                .accessibilityLabel(String(localized: "\(source.name) source, opens in your browser"))
            }
            if source == .custom {
                Button("Import CSV…", action: onImport)
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("pricing.importCSV")
            }
        }
    }
}
