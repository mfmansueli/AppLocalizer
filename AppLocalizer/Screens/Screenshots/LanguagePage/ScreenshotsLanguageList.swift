//
//  ScreenshotsLanguageList.swift
//  AppLocalizer
//

import SwiftUI

/// All Languages: every language with its own screenshots, with its state
/// and the captions suggested in it. Clicking one shows it.
struct ScreenshotsLanguageList: View {
    @Bindable var viewModel: ScreenshotsViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.pageLocales.enumerated()), id: \.element) { index, locale in
                if index > 0 { Divider() }
                row(locale)
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.page.allLanguages")
    }

    private func row(_ locale: StoreLocale) -> some View {
        let count = viewModel.proposedCaptions(in: locale).count
        return Button {
            viewModel.pageLocale = locale
            viewModel.pageShowsAll = false
        } label: {
            HStack(spacing: Spacing.medium) {
                Text(locale.regionCode.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                    .frame(width: 30, height: 22)
                    .background(Palette.fill2, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(locale.name)
                    Text(viewModel.pageStatus(of: locale))
                        .font(.caption)
                        .foregroundStyle(count > 0 ? AnyShapeStyle(Palette.machineTranslated) : AnyShapeStyle(Palette.label2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if count > 0 {
                    SuggestionBadge(count: count)
                } else {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.increase)
                        .accessibilityHidden(true)
                }
                Image(systemName: "chevron.forward")
                    .font(.caption)
                    .foregroundStyle(Palette.label3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(locale.name), \(viewModel.pageStatus(of: locale))"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("screenshots.page.language.\(locale.code)")
    }
}
