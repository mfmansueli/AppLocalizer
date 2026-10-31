//
//  StoreProductHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The product page's top: icon, name, subtitle, stats and Get, in the
/// preview's language.
struct StoreProductHeader: View {
    let app: StoreApp
    let preview: StudioPreview
    var iconSize: CGFloat = 64
    var compact = false

    var body: some View {
        HStack(alignment: compact ? .center : .top, spacing: compact ? Spacing.small : Spacing.medium) {
            AppIconTile(name: app.name, icon: app.icon, size: iconSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                Text(preview.name)
                    .font(compact ? .callout.weight(.semibold) : .title3.weight(.semibold))
                    .lineLimit(1)
                    .accessibilityIdentifier(compact ? "studio.search.name" : "studio.store.name")
                if let subtitle = preview.subtitle {
                    Text(subtitle)
                        .font(compact ? .caption : .callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityIdentifier(compact ? "studio.search.subtitle" : "studio.store.subtitle")
                }
                if let stats = preview.statsLine, !compact {
                    Text(stats).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: Spacing.small)
            Text(preview.getTitle)
                .font((compact ? Font.caption : .callout).weight(.semibold))
                .foregroundStyle(compact ? Color.accentColor : .white)
                .padding(.horizontal, compact ? 14 : 20)
                .padding(.vertical, compact ? 4 : 6)
                .background(compact ? AnyShapeStyle(.quaternary) : AnyShapeStyle(Color.accentColor), in: Capsule())
                .accessibilityLabel(Text(preview.getTitle))
                .accessibilityIdentifier(compact ? "studio.search.get" : "studio.store.get")
        }
    }
}
