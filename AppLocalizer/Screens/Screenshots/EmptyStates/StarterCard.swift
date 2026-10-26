//
//  StarterCard.swift
//  AppLocalizer
//

import SwiftUI

/// One starter template: its first three slots rendered with the app's
/// captures, what it suits, and Use This Template.
struct StarterCard: View {
    let starter: TemplateStarter
    let images: [CGImage?]
    let thumbnailHeight: CGFloat
    var onUse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: 4) {
                ForEach(images.indices, id: \.self) { index in
                    thumbnail(images[index])
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.small)
            .background(Palette.stage, in: RoundedRectangle(cornerRadius: Radius.field))
            Text(starter.title)
                .font(.headline)
                .padding(.top, Spacing.xxSmall)
            Text(starter.summary)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button("Use This Template", action: onUse)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(Text("Use \(starter.title)"))
                .accessibilityIdentifier("screenshots.starter.\(starter.rawValue)")
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }

    private func thumbnail(_ image: CGImage?) -> some View {
        let width = CGFloat(StarterPreview.pixelWidth / 2)
        return Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
            } else {
                Palette.fill2.overlay { ProgressView().controlSize(.small) }
            }
        }
        .frame(width: width, height: thumbnailHeight)
        .clipShape(RoundedRectangle(cornerRadius: Radius.flag))
        .accessibilityHidden(true)
    }
}
