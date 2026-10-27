//
//  PriceHistogramView.swift
//  AppLocalizer
//

import SwiftUI

/// Territories bucketed by how far the price they show sits from Apple's
/// equalized price, in 10% steps: teal below, neutral around it, orange
/// above, with the median and the counts.
struct PriceHistogramView: View {
    let histogram: PriceHistogram

    /// The tallest bar; the area above it holds the count labels.
    private let barHeight: CGFloat = 190
    private let chartHeight: CGFloat = 230

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.small) { heading }
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) { heading }
                }
                VStack(spacing: Spacing.xSmall) {
                    bars
                    labels
                }
                Text("""
                Territories bucketed by how far the proposed price (or the current one where nothing is proposed) sits \
                from Apple’s equalized price. Teal is below equalized, orange above.
                """)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: 680, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.xxLarge)
            .padding(.vertical, Spacing.medium + 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.histogram")
    }

    @ViewBuilder
    private var heading: some View {
        Text("Distance from Apple’s equalized price")
            .font(.headline)
        Text(histogram.summary)
            .font(.callout)
            .foregroundStyle(Palette.label2)
            .monospacedDigit()
            .accessibilityIdentifier("pricing.histogram.summary")
    }

    private var bars: some View {
        HStack(alignment: .bottom, spacing: Spacing.xSmall) {
            ForEach(histogram.buckets) { bucket in
                VStack(spacing: Spacing.xxSmall) {
                    Text(bucket.count, format: .number)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .monospacedDigit()
                    UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4, style: .continuous)
                        .fill(color(for: bucket.tone))
                        .frame(maxWidth: 46)
                        .frame(height: height(for: bucket))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(bucket.label)
                .accessibilityValue(bucket.count == 1 ? String(localized: "1 territory") : String(localized: "\(bucket.count) territories"))
            }
        }
        .frame(height: chartHeight, alignment: .bottom)
        .padding(.horizontal, Spacing.xxSmall)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.separator2).frame(height: 0.5)
        }
    }

    private var labels: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(histogram.buckets) { bucket in
                Text(bucket.label)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.xxSmall)
        .accessibilityHidden(true)
    }

    private func height(for bucket: PriceHistogram.Bucket) -> CGFloat {
        guard histogram.maximumCount > 0 else { return 0 }
        return barHeight * CGFloat(bucket.count) / CGFloat(histogram.maximumCount)
    }

    private func color(for tone: PriceHistogram.Tone) -> Color {
        switch tone {
        case .below: Palette.decreaseMark
        case .atEqualized: Palette.label3
        case .above: Palette.increaseMark
        }
    }
}
