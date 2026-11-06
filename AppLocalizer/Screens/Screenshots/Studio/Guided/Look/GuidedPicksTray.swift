//
//  GuidedPicksTray.swift
//  AppLocalizer
//

import SwiftUI

/// My picks, under a template or scene browser: three places, each a
/// pick (its thumbnails, "Pick 2", its name and ✕) or "Pick 3 · empty".
/// Clicking a pick's thumbnails previews it again.
struct GuidedPicksTray<Item: Hashable, Thumbnail: View>: View {
    let picks: [Item]
    let text: String
    let emptyHeight: CGFloat
    let identifier: String
    let name: (Item) -> String
    let preview: (Item) -> Void
    let remove: (Item) -> Void
    @ViewBuilder let thumbnail: (Item) -> Thumbnail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("\(Text("My picks").fontWeight(.semibold)) \(Text("· \(text)").foregroundStyle(Palette.label2))")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("\(identifier).text")
            HStack(spacing: 10) {
                ForEach(0..<AutopilotShotStyle.maximumTemplates, id: \.self) { index in
                    if index < picks.count {
                        filled(picks[index], number: index + 1)
                    } else {
                        empty(number: index + 1)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    private func filled(_ item: Item, number: Int) -> some View {
        HStack(spacing: Spacing.small) {
            Button { preview(item) } label: { thumbnail(item) }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Preview \(name(item))"))
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                Text("Pick \(number)").font(.caption).foregroundStyle(Palette.label2)
                Text(name(item)).font(.callout.weight(.semibold)).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                remove(item)
            } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Remove \(name(item)) from My Picks"))
            .accessibilityIdentifier("\(identifier).remove.\(number)")
        }
        .padding(Spacing.xSmall)
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.accent, lineWidth: 1.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(identifier).pick.\(number)")
    }

    private func empty(number: Int) -> some View {
        Text("Pick \(number) · empty")
            .font(.callout)
            .foregroundStyle(Palette.label3)
            .frame(maxWidth: .infinity)
            .frame(height: emptyHeight)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                    .strokeBorder(Palette.separator2, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            )
            .accessibilityIdentifier("\(identifier).empty.\(number)")
    }
}
