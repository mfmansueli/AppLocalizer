//
//  AppStorePagePreview.swift
//  AppLocalizer
//

import SwiftUI

/// The app's App Store page in miniature, in the storefront's own language
/// and direction: icon, name and Get, ratings, age and category, screenshots,
/// the texts, What's New and the purchases. On the Overview each part has a
/// tag that opens the section editing it, shown while the pointer is over
/// the part or when it has suggestions.
struct AppStorePagePreview<Shots: View>: View {
    let model: AppStorePreviewModel
    let appName: String
    var icon: AppIcon?
    var links: AppStorePreviewLinks?
    @ViewBuilder var shots: () -> Shots
    /// The part under the pointer, by its link's title: its tag shows.
    @State private var hovered: String?

    private static var getBlue: Color { Color(red: 0.04, green: 0.52, blue: 1) }

    var body: some View {
        VStack(spacing: 0) {
            row(link: links?.storePage) { header }
            divider
            row(link: links?.appInformation, vertical: 8) { stats }
            divider
            row(link: links?.screenshots) { shots() }
            divider
            row(link: nil) { texts }
            divider
            row(link: nil) { whatsNew }
            if !model.purchases.isEmpty {
                divider
                row(link: links?.pricing) { purchases }
            }
        }
        .padding(6)
        .background(Palette.content, in: shape)
        .overlay(shape.strokeBorder(Palette.separator2, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
        .environment(\.layoutDirection, model.locale.isRTL ? .rightToLeft : .leftToRight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Preview on the App Store"))
        .accessibilityIdentifier("storePreview")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(height: 0.5)
            .padding(.horizontal, 10)
    }

    private func row(link: AppStorePreviewLink?, vertical: CGFloat = 9, @ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, vertical)
            .overlay(alignment: .topTrailing) {
                // Only over the part pointed at, or with suggestions: always
                // shown, they covered Alba's name, the Category label and
                // the third screenshot's caption.
                if let link { tag(link).opacity(hovered == link.title || link.count > 0 ? 1 : 0) }
            }
            .onHover { inside in
                guard let title = link?.title else { return }
                if inside {
                    hovered = title
                } else if hovered == title {
                    hovered = nil
                }
            }
            .animation(.easeOut(duration: 0.15), value: hovered)
    }

    private func tag(_ link: AppStorePreviewLink) -> some View {
        Button(action: link.open) {
            HStack(spacing: Spacing.tiny) {
                Text(link.title)
                SuggestionBadge(count: link.count, isSmall: true)
                Image(systemName: "chevron.forward")
                    .imageScale(.small)
            }
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 0.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, .leftToRight)
        .padding(Spacing.xxSmall)
        .accessibilityLabel(Text(link.count > 0 ? String(localized: "Edit in \(link.title), \(link.count) suggestions") : String(localized: "Edit in \(link.title)")))
    }

    private func highlighted(_ text: AppStorePreviewText, display: String? = nil) -> some View {
        Text(display ?? text.value)
            .modifier(AppStorePreviewHighlight(isOn: text.isSuggested))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            AppIconTile(name: appName, icon: icon, size: 60)
            VStack(alignment: .leading, spacing: 2) {
                highlighted(model.name.value.isEmpty ? AppStorePreviewText(value: appName) : model.name)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                highlighted(model.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.label2)
                    .lineLimit(2)
                HStack(spacing: 7) {
                    Text(model.words.get)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 24)
                        .background(Self.getBlue, in: Capsule())
                    if !model.purchases.isEmpty {
                        Text(model.words.inAppPurchases)
                            .font(.system(size: 9))
                            .foregroundStyle(Palette.label2)
                            .lineLimit(2)
                            .frame(maxWidth: 70, alignment: .leading)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var stats: some View {
        HStack(alignment: .top, spacing: Spacing.xSmall) {
            stat(top: model.ratingCountText, big: model.ratingText, bottom: "★★★★★")
            if let age = model.ageRating {
                stat(top: String(localized: "Age"), big: age, bottom: model.words.yearsOld)
            }
            if let category = model.category {
                stat(top: String(localized: "Category"), big: nil, bottom: category)
            }
        }
    }

    private func stat(top: String, big: String?, bottom: String) -> some View {
        VStack(spacing: 1) {
            Text(top)
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
            if let big {
                Text(big)
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
            }
            Text(bottom)
                .font(.caption2)
                .foregroundStyle(Palette.label3)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !model.promotionalText.value.isEmpty {
                highlighted(model.promotionalText)
                    .font(.system(size: 12))
                    .lineLimit(3)
            }
            highlighted(model.description, display: AppStorePreviewModel.clipped(model.description.value, to: 200))
                .font(.system(size: 12))
                .foregroundStyle(Palette.label2)
                .lineLimit(3)
            Text(model.words.more)
                .font(.caption2)
                .foregroundStyle(Self.getBlue)
        }
    }

    private var whatsNew: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(model.words.whatsNew)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !model.versionString.isEmpty {
                    Text(model.words.versionText(model.versionString))
                        .font(.caption2)
                        .foregroundStyle(Palette.label2)
                }
            }
            highlighted(model.whatsNew, display: AppStorePreviewModel.clipped(model.whatsNew.value, to: 160))
                .font(.system(size: 12))
                .lineLimit(3)
        }
    }

    private var purchases: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(model.words.inAppPurchases)
                .font(.subheadline.weight(.semibold))
            ForEach(model.purchases) { purchase in
                HStack(spacing: Spacing.small) {
                    Text(purchase.name)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let price = purchase.price {
                        Text(price)
                            .monospacedDigit()
                            .foregroundStyle(Palette.label2)
                    }
                }
                .font(.system(size: 12))
            }
        }
    }
}
