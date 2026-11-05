//
//  AutopilotShotTemplateCard.swift
//  AppLocalizer
//

import SwiftUI

/// A picked gallery template on the plan: its first slots rendered with
/// the app's captions and captures, its pick number, its name and style,
/// and a button that takes it out.
struct AutopilotShotTemplateCard: View {
    let starter: TemplateStarter
    /// 1, 2, 3.
    let number: Int
    /// The rendered slots, nil while one renders.
    let images: [CGImage?]
    let remove: () -> Void

    /// The slots a pick shows.
    static let slotCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            slots
            HStack(alignment: .top, spacing: 4) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(starter.title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Text(starter.style.title)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: remove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.label3)
                }
                .buttonStyle(.plain)
                .help(Text("Remove \(starter.title)"))
                .accessibilityLabel(Text("Remove \(starter.title)"))
                .accessibilityIdentifier("autopilot.plan.shotTemplate.\(starter.rawValue).remove")
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).fill(Palette.raised))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.accent, lineWidth: 2))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.shotTemplate.\(starter.rawValue)")
    }

    private var slots: some View {
        HStack(spacing: starter == .panorama ? 0 : 4) {
            ForEach(0..<Self.slotCount, id: \.self) { slot in
                thumbnail(images.indices.contains(slot) ? images[slot] : nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.small)
        .padding(.horizontal, 6)
        .background(Palette.stage, in: RoundedRectangle(cornerRadius: Radius.field))
        .overlay(alignment: .topTrailing) {
            Text(number.formatted())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Palette.accent))
                .padding(5)
                .accessibilityLabel(Text("Pick \(number)"))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(starter.title), first \(Self.slotCount) screenshots"))
    }

    private func thumbnail(_ image: CGImage?) -> some View {
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
        .aspectRatio(width / StarterPreview.thumbnailHeight, contentMode: .fit)
        .frame(maxWidth: width)
        .clipShape(RoundedRectangle(cornerRadius: starter == .panorama ? 0 : 4))
    }
}
