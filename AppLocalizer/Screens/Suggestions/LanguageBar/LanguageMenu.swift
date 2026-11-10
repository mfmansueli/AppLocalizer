//
//  LanguageMenu.swift
//  AppLocalizer
//

import SwiftUI

/// The language bar's menu: languages with suggestions first, each with its
/// count, then the ones up to date; a language the App Store doesn't have
/// yet says New page. A popover, because a menu can't show badges.
struct LanguageMenu: View {
    let model: LanguageBarModel
    let onSelect: (StoreLocale) -> Void
    let onAcceptAll: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                group(String(localized: "Suggestions to review"), model.withSuggestions)
                group(String(localized: "Up to date"), model.upToDate)
                Divider()
                    .padding(.vertical, 5)
                    .padding(.horizontal, Spacing.xxSmall)
                Button(action: onAcceptAll) {
                    Label(model.menuAcceptAllTitle, systemImage: "sparkles")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 28)
                        .padding(.horizontal, Spacing.small)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.accentText)
                .disabled(model.totalCount == 0)
                .accessibilityIdentifier("languageBar.menu.acceptAll")
            }
            .padding(Spacing.xSmall)
        }
        .frame(width: 330)
        .frame(maxHeight: 460)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("languageBar.menu")
    }

    @ViewBuilder
    private func group(_ title: String, _ entries: [LanguageBarEntry]) -> some View {
        if !entries.isEmpty {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
                .padding(.horizontal, Spacing.small)
                .padding(.top, 7)
                .padding(.bottom, 3)
            ForEach(entries) { entry in
                row(entry)
            }
        }
    }

    private func row(_ entry: LanguageBarEntry) -> some View {
        Button {
            onSelect(entry.locale)
        } label: {
            HStack(spacing: Spacing.small) {
                FlagTile(regionCode: entry.locale.regionCode)
                    .frame(width: 20)
                Text(entry.locale.name)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if entry.comingCount > 0 {
                    Text("\(entry.comingCount) coming")
                        .font(.caption2)
                        .foregroundStyle(Palette.label2)
                        .fixedSize()
                }
                if entry.isNewPage {
                    Pill(text: String(localized: "New page"), style: .accent)
                        .fixedSize()
                }
                SuggestionBadge(count: entry.count)
                if entry.count == 0 {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.label3)
                }
            }
            .frame(minHeight: 28)
            .padding(.horizontal, Spacing.small)
            .background(
                entry.locale == model.current ? AnyShapeStyle(Palette.accentTint) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(entry.accessibilityText))
        .accessibilityAddTraits(entry.locale == model.current ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("languageBar.menu.\(entry.locale.code)")
    }
}
