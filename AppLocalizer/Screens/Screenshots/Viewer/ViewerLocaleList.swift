//
//  ViewerLocaleList.swift
//  AppLocalizer
//

import SwiftUI

/// ALL LOCALES · SLOT n: the primary locale, then the others in App Store
/// Connect's order, each with a dot for its state on this slot. Clicking
/// one shows it.
struct ViewerLocaleList: View {
    let viewModel: ScreenshotsViewModel
    let target: ScreenshotViewerTarget

    var body: some View {
        ViewerSection(title: String(localized: "All Locales · Slot \(target.slot + 1)")) {
            VStack(spacing: 1) {
                ForEach(viewModel.viewerLocales, id: \.self) { code in
                    row(code)
                }
            }
        }
    }

    private func row(_ code: String) -> some View {
        let locale = viewModel.locale(code: code)
        let cell = viewModel.matrix.cell(locale: code, displayType: viewModel.displayType, slot: target.slot)
        let isSelected = code == target.locale
        return Button {
            viewModel.showInViewer(locale: code)
        } label: {
            HStack(spacing: Spacing.small) {
                FlagTile(regionCode: locale?.regionCode ?? "")
                    .frame(width: 20)
                Text(locale?.name ?? code)
                    .font(.callout)
                    .lineLimit(1)
                Spacer(minLength: Spacing.small)
                LocaleStateDot(state: cell?.state)
            }
            .padding(.horizontal, Spacing.xSmall)
            .padding(.vertical, 4)
            .background(isSelected ? Palette.fill2 : .clear, in: RoundedRectangle(cornerRadius: Radius.badge))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(locale?.name ?? code), \(cell?.state.title ?? "")"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("screenshots.viewer.locale.\(code)")
    }
}
