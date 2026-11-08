//
//  RetentionKindSection.swift
//  AppLocalizer
//

import SwiftUI

/// Shows: message only, with an image, or with an offer; then the image
/// (Choose…) or the subscriptions' offers (New Offer…).
struct RetentionKindSection: View {
    let model: RetentionModel
    let message: RetentionMessage

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            row(String(localized: "Shows")) {
                RetentionSegmentedControl(
                    label: String(localized: "Shows"),
                    segments: RetentionMessageKind.allCases.map {
                        RetentionSegment(value: $0, title: $0.title, identifier: "retention.kind.\($0.rawValue)")
                    },
                    selection: Binding(get: { message.kind }, set: model.setKind),
                    identifier: "retention.kind"
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            switch message.kind {
            case .message: EmptyView()
            case .image: imageRow
            case .offer: offersRow
            }
        }
    }

    private func row(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            Text(title)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .frame(width: 96, alignment: .leading)
            content()
        }
    }

    private var imageRow: some View {
        row(String(localized: "Image")) {
            if let image = message.image {
                RetentionArtworkView(image: image)
                    .frame(width: 150, height: 150 * CGFloat(image.pixelHeight) / CGFloat(max(1, image.pixelWidth)))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text(imageDetail(image))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No image yet. It has to be a PNG 3840 wide and 160 to 2160 tall, with no transparency.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button("Choose…", action: model.chooseImage)
                .accessibilityIdentifier("retention.image.choose")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.image")
    }

    /// "Still Lake · from the Asset Library · 3840 × 1000 · from the
    /// header scenes · PNG, no transparency, reads in light and dark".
    private func imageDetail(_ image: RetentionImage) -> String {
        let from = image.assetID == nil ? String(localized: "made on this Mac, uploaded when you push") : String(localized: "from the Asset Library")
        var parts = [image.name, from, image.sizeText]
        if let note = image.note { parts.append(note) }
        if let problem = image.problems.first {
            parts.append(problem.message)
        } else {
            parts.append(String(localized: "PNG, no transparency, reads in light and dark"))
        }
        return parts.joined(separator: " · ")
    }

    private var offersRow: some View {
        row(String(localized: "Offers")) {
            let summary = model.offersSummary(for: message)
            Text(summary.isEmpty
                ? String(localized: "No retention offer for these subscriptions yet. Add one, or show the message only.")
                : String(localized: "\(summary). When someone is eligible, Apple shows the best offer instead of the image."))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("New Offer…") { model.isOfferSheetPresented = true }
                .accessibilityIdentifier("retention.offers.new")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.offersRow")
    }
}
