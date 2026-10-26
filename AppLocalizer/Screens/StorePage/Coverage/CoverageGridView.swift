//
//  CoverageGridView.swift
//  AppLocalizer
//

import SwiftUI

/// Locales × the nine fields, grouped under "App information · all
/// versions" and "Version 1.4", with a legend underneath. A cell opens the
/// editor on that locale and field. `Table` can't draw the two-level
/// header, so it's a grid with a pinned header; columns share the width
/// left after the locale column, and scroll sideways below 72 pt each.
struct CoverageGridView: View {
    let viewModel: StorePageViewModel

    private static let localeWidth: CGFloat = 210
    private static let minimumCellWidth: CGFloat = 72
    private static let rowHeight: CGFloat = 32
    private static let gap = Spacing.xxSmall
    private static let inset = Spacing.medium

    var body: some View {
        VStack(spacing: 0) {
            if let grid = viewModel.coverage {
                GeometryReader { proxy in
                    let width = max(proxy.size.width, Self.minimumWidth(columns: grid.fields.count))
                    let cellWidth = Self.cellWidth(in: width, columns: grid.fields.count)
                    ScrollView([.vertical, .horizontal]) {
                        table(grid, cellWidth: cellWidth)
                            .frame(width: width)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("Store page coverage by locale and field"))
                .accessibilityIdentifier("storePage.coverage")
            }
            Divider()
            CoverageLegend()
        }
    }

    private static func minimumWidth(columns: Int) -> CGFloat {
        localeWidth + CGFloat(columns) * (minimumCellWidth + gap) + inset * 2
    }

    private static func cellWidth(in width: CGFloat, columns: Int) -> CGFloat {
        guard columns > 0 else { return minimumCellWidth }
        return (width - inset * 2 - localeWidth - CGFloat(columns) * gap) / CGFloat(columns)
    }

    private func table(_ grid: ListingCoverageGrid, cellWidth: CGFloat) -> some View {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                ForEach(grid.rows) { row in
                    rowView(row, cellWidth: cellWidth)
                    Divider()
                }
            } header: {
                header(grid, cellWidth: cellWidth)
            }
        }
    }

    private func header(_ grid: ListingCoverageGrid, cellWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: Self.gap) {
                Color.clear.frame(width: Self.localeWidth, height: 1)
                ForEach([ListingFieldLevel.app, .version], id: \.self) { level in
                    let count = grid.fields(at: level).count
                    if count > 0 {
                        groupHeader(level.groupTitle(version: grid.version.versionString))
                            .frame(width: CGFloat(count) * cellWidth + CGFloat(count - 1) * Self.gap)
                    }
                }
            }
            .padding(.top, Spacing.small)
            HStack(spacing: Self.gap) {
                Text("Locale")
                    .frame(width: Self.localeWidth, alignment: .leading)
                ForEach(grid.fields) { field in
                    Text(field.shortTitle)
                        .lineLimit(1)
                        .frame(width: cellWidth)
                }
            }
            .font(.callout.weight(.medium))
            .foregroundStyle(Palette.label2)
            .frame(height: 28)
        }
        .padding(.horizontal, Self.inset)
        .background(Palette.content)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityHidden(true)
    }

    private func groupHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Palette.label2)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 3)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.separator2).frame(height: 1.5)
            }
    }

    private func rowView(_ row: ListingCoverageRow, cellWidth: CGFloat) -> some View {
        HStack(spacing: Self.gap) {
            LocaleLabel(locale: row.locale, isPrimary: row.isPrimary)
                .frame(width: Self.localeWidth, alignment: .leading)
            ForEach(row.cells) { cell in
                CoverageCellButton(cell: cell) {
                    viewModel.openEditor(cell.key.locale, field: cell.key.field)
                }
                .frame(width: cellWidth)
            }
        }
        .padding(.horizontal, Self.inset)
        .frame(height: Self.rowHeight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.row.\(row.locale.code)")
    }
}
