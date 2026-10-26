//
//  AppRow.swift
//  AppLocalizer
//

import SwiftUI

/// One app in the sidebar: icon, name and bundle ID, with a dot before the
/// name for unpushed changes, a locale coverage ring and a tag counting the
/// territories whose price likely holds people back.
struct AppRow: View {
    let app: StoreApp
    var indicators = AppIndicators()

    var body: some View {
        HStack(spacing: 10) {
            AppIconTile(name: app.name, icon: app.icon)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    if indicators.hasUnpushedChanges {
                        UnsavedDot(size: 7)
                    }
                    Text(app.name)
                        .lineLimit(1)
                }
                Text(app.bundleID)
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                if let localeCount = indicators.localeCount {
                    CoverageRing(count: localeCount)
                }
                if let count = indicators.priceSuggestionCount, count > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "tag.fill")
                            .imageScale(.small)
                        Text(count, format: .number)
                            .monospacedDigit()
                    }
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
                    .accessibilityElement()
                    .accessibilityLabel(Text("\(count) territories likely held back by price"))
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        AppRow(app: StoreApp(id: "1", name: "Lumen Journal", bundleID: "dev.northpier.lumen", icon: .symbol("moon.fill", top: 0x7C86FF, bottom: 0x3A2FB8)),
               indicators: AppIndicators(pendingChangeCount: 2, localeCount: 10, priceSuggestionCount: 146))
        AppRow(app: StoreApp(id: "2", name: "Quiet Timer", bundleID: "dev.northpier.quiet"), indicators: AppIndicators(localeCount: 12))
    }
    .frame(width: 260)
}
