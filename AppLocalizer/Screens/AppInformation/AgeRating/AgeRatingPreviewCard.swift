//
//  AgeRatingPreviewCard.swift
//  AppLocalizer
//

import SwiftUI

/// The rating preview: the rating the App Store would show, what the
/// answers calculate, what App Store Connect has now, and the regional
/// ratings.
struct AgeRatingPreviewCard: View {
    let preview: AgeRatingPreview
    let currentRating: String?
    let changesWithPush: Bool

    var body: some View {
        Card {
            Text("RATING PREVIEW")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
            HStack(alignment: .top, spacing: Spacing.medium) {
                Text(preview.effective.title)
                    .font(.system(size: 26, weight: .semibold))
                    .monospacedDigit()
                    .frame(width: 64, height: 64)
                    .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.label, lineWidth: 2))
                    .accessibilityLabel(Text("Rating \(preview.effective.title)"))
                    .accessibilityIdentifier("appInformation.age.rating")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calculated: **\(preview.calculated.title)**")
                    Text("In App Store Connect now: \(currentRating ?? String(localized: "not rated"))")
                        .foregroundStyle(Palette.label2)
                }
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            }
            if changesWithPush {
                Pill(text: String(localized: "Changes with your next push"), systemImage: "circle.fill", style: .accent)
            }
            Text("BY REGION")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
                .padding(.top, Spacing.xxSmall)
            VStack(spacing: 0) {
                regionRow(String(localized: "Australia"), preview.australia)
                regionRow(String(localized: "Brazil · self-rated"), preview.brazil)
                regionRow(String(localized: "Republic of Korea"), preview.korea)
                regionRow(String(localized: "Everywhere else"), preview.effective.title)
            }
            Text("Regional values follow Apple’s published tables. Regulators in Australia and Brazil can replace them with an official rating.")
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("appInformation.age.preview")
    }

    private func regionRow(_ region: String, _ rating: String) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text(region)
                Spacer()
                Text(rating)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .font(.caption)
            .padding(.vertical, Spacing.xxSmall + 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AgeRatingPreviewCard(
        preview: AgeRatingCalculator.preview(for: AgeRatingAnswers([.wellness: .affirmative])),
        currentRating: "4+",
        changesWithPush: true
    )
    .frame(width: 250)
    .padding()
}
