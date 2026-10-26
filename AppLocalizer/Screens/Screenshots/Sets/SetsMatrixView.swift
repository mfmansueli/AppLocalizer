//
//  SetsMatrixView.swift
//  AppLocalizer
//

import SwiftUI

/// Sets: every localized locale × every slot on one display type, with
/// the restored locales and the collapsed fallback locales below. Scrolls
/// both ways; the column header stays on top and the locale column stays
/// at the leading edge.
struct SetsMatrixView: View {
    @Bindable var viewModel: ScreenshotsViewModel
    @State private var scrollX: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0

    var body: some View {
        let columns = SetsColumns(
            thumbnailWidth: viewModel.thumbnailWidth,
            thumbnailHeight: viewModel.thumbnailHeight,
            slotCount: viewModel.matrix.slotCount
        )
        let sticky = max(0, scrollX)
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(viewModel.groups) { group in
                        groupContent(group, columns: columns, sticky: sticky)
                    }
                    Color.clear.frame(height: Spacing.xxLarge)
                } header: {
                    SetsColumnHeader(
                        columns: columns,
                        slots: viewModel.slotTitles,
                        showsInSearch: viewModel.showsInSearch(slot:),
                        stickyOffset: sticky
                    )
                }
            }
            .frame(width: max(viewportWidth, columns.total), alignment: .leading)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.x
        } action: { _, offset in
            scrollX = offset
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            viewportWidth = width
        }
        .background(Palette.content)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.sets")
    }

    @ViewBuilder
    private func groupContent(_ group: SetsGroup, columns: SetsColumns, sticky: CGFloat) -> some View {
        SetsGroupHeader(
            group: group,
            isExpanded: viewModel.showsFallbackRows,
            stickyOffset: sticky,
            onToggle: group.kind == .fallback ? { viewModel.showsFallbackRows.toggle() } : nil
        )
        ForEach(group.rows) { row in
            SetsRowView(
                viewModel: viewModel,
                row: row,
                columns: columns,
                opensViewer: group.kind == .localized,
                stickyOffset: sticky
            )
        }
    }
}
