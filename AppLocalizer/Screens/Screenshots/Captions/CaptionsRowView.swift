//
//  CaptionsRowView.swift
//  AppLocalizer
//

import SwiftUI

/// One locale: its flag and name, then a cell per slot.
struct CaptionsRowView: View {
    let model: CaptionsViewModel
    let row: CaptionsRow
    let cellWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(spacing: Spacing.xSmall) {
                FlagTile(regionCode: row.locale.regionCode)
                Text(row.locale.name)
                    .font(.callout)
                    .lineLimit(1)
                if row.isPrimary {
                    Pill(text: String(localized: "Primary"), style: .outline)
                }
            }
            .padding(.leading, Spacing.small)
            .frame(width: CaptionsTable.localeColumnWidth, alignment: .leading)
            ForEach(row.cells) { cell in
                CaptionCellView(
                    cell: cell,
                    localeName: row.locale.name,
                    isRightToLeft: ScreenshotScript(locale: row.locale).isRightToLeft,
                    isSelected: model.selection == cell.key
                ) {
                    model.select(cell.key)
                }
                .frame(width: cellWidth)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 2)
        .frame(minHeight: 74)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.captions.row.\(row.locale.code)")
    }
}
