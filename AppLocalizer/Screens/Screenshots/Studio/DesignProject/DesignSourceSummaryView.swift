//
//  DesignSourceSummaryView.swift
//  AppLocalizer
//

import SwiftUI

/// What was found in the design source: colors, type, logo and voice, so
/// you can see it's the right system.
struct DesignSourceSummaryView: View {
    let summary: DesignSourceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Label(summary.title, systemImage: "checkmark")
                    .font(.headline)
                Spacer()
                if let updated = summary.updated {
                    Text("Updated \(updated.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Spacing.large, verticalSpacing: Spacing.xSmall) {
                if !summary.colors.isEmpty {
                    GridRow {
                        label("Colors")
                        FlowLayout(spacing: Spacing.small) {
                            ForEach(summary.colors, id: \.self) { swatch in
                                HStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(TemplateColor(swatch.hex)?.color ?? .gray)
                                        .frame(width: 14, height: 14)
                                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Palette.separator, lineWidth: 0.5))
                                    Text(swatch.name).font(.callout)
                                }
                            }
                        }
                    }
                }
                if let typefaces = summary.typefaces { GridRow { label("Type"); Text(typefaces).font(.callout) } }
                if let logo = summary.logo { GridRow { label("Logo"); Text(logo).font(.callout) } }
                if let voice = summary.voice { GridRow { label("Voice"); Text("“\(voice)”").font(.callout) } }
            }
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("designProject.summary")
    }

    private func label(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.callout).foregroundStyle(Palette.label2)
    }
}
