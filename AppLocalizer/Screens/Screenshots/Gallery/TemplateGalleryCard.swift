//
//  TemplateGalleryCard.swift
//  AppLocalizer
//

import SwiftUI

/// One gallery template: its five slots rendered with the app's captions
/// and captures, its name (and In use), tags, what it's like, which
/// scripts its font draws, and the button that picks it. Autopilot's
/// template picker numbers the ones picked.
struct TemplateGalleryCard: View {
    let starter: TemplateStarter
    let images: [CGImage?]
    let fontNote: String
    let isInUse: Bool
    let buttonTitle: String
    let isProminent: Bool
    /// 1, 2, 3 when picked for an Autopilot run.
    var pickNumber: Int?
    var onUse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: starter == .panorama ? 0 : 4) {
                ForEach(images.indices, id: \.self) { index in
                    thumbnail(images[index], slot: index)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(Palette.stage, in: RoundedRectangle(cornerRadius: Radius.field))
            .overlay(alignment: .topTrailing) {
                if let pickNumber {
                    Text(pickNumber.formatted())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Palette.accent))
                        .padding(5)
                        .accessibilityLabel(Text("Pick \(pickNumber)"))
                        .accessibilityIdentifier("screenshots.gallery.card.\(starter.rawValue).pick")
                }
            }
            HStack(spacing: Spacing.xSmall) {
                Text(starter.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isInUse {
                    Pill(text: String(localized: "In use"), style: .accent)
                }
            }
            FlowLayout(spacing: 4) {
                ForEach(starter.tags, id: \.self) { tag in
                    Pill(text: tag)
                }
            }
            Text(starter.summary)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: .infinity, alignment: .top)
            Text(fontNote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            button
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(pickNumber == nil ? Palette.separator : Palette.accent, lineWidth: pickNumber == nil ? 0.5 : 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.gallery.card.\(starter.rawValue)")
    }

    @ViewBuilder
    private var button: some View {
        let button = Button(buttonTitle, action: onUse)
            .controlSize(.small)
            .accessibilityLabel(Text("\(buttonTitle): \(starter.title)"))
            .accessibilityIdentifier("screenshots.starter.\(starter.rawValue)")
        if isProminent {
            button.buttonStyle(.borderedProminent)
        } else {
            button
        }
    }

    private func thumbnail(_ image: CGImage?, slot: Int) -> some View {
        let width = CGFloat(StarterPreview.thumbnailWidth)
        return Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
            } else {
                Palette.fill2.overlay { ProgressView().controlSize(.mini) }
            }
        }
        .frame(width: width, height: StarterPreview.thumbnailHeight)
        .clipShape(RoundedRectangle(cornerRadius: starter == .panorama ? 0 : 4))
        .accessibilityElement()
        .accessibilityLabel(Text("\(starter.title), slot \(slot + 1)"))
    }
}
