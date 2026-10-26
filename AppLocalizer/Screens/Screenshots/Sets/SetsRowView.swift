//
//  SetsRowView.swift
//  AppLocalizer
//

import SwiftUI

/// One locale across the slots: its header (kept in view while scrolling
/// sideways), its App Preview, and a thumbnail per slot.
struct SetsRowView: View {
    let viewModel: ScreenshotsViewModel
    let row: SetsRow
    let columns: SetsColumns
    let opensViewer: Bool
    let stickyOffset: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            SetsLocaleHeader(row: row)
                .frame(width: SetsColumns.locale - Spacing.small, alignment: .leading)
                .padding(.trailing, Spacing.small)
                .padding(.leading, SetsColumns.leading)
                .frame(maxHeight: .infinity)
                .background(Palette.content)
                .offset(x: stickyOffset)
                .zIndex(1)
            AppPreviewTile(previews: row.previews, width: columns.previewWidth, height: columns.previewHeight)
                .frame(width: SetsColumns.preview)
            ForEach(row.cells) { cell in
                ThumbnailCell(
                    cell: cell,
                    image: viewModel.thumbnail(for: cell),
                    isRendering: viewModel.isRendering(cell),
                    width: columns.thumbnailWidth,
                    height: columns.thumbnailHeight,
                    localeName: row.locale.name,
                    onOpen: opensViewer && cell.image != CellImageSource.none ? { viewModel.openViewer(cell.key) } : nil
                )
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.small)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.row.\(row.locale.code)")
    }
}
