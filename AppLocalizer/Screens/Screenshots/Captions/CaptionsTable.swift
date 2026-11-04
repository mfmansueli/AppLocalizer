//
//  CaptionsTable.swift
//  AppLocalizer
//

import SwiftUI

/// Locales × slots: a column per slot, a row per localized locale, and
/// the count of locales outside the scope.
struct CaptionsTable: View {
    let viewModel: ScreenshotsViewModel
    let model: CaptionsViewModel

    static let localeColumnWidth: CGFloat = 190
    static let minimumCellWidth: CGFloat = 150

    var body: some View {
        GeometryReader { proxy in
            let cellWidth = cellWidth(for: proxy.size.width)
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        CaptionsGroupHeader(title: String(localized: "Localized sets"), count: model.rows.count)
                        ForEach(model.rows) { row in
                            CaptionsRowView(model: model, row: row, cellWidth: cellWidth)
                            Divider()
                        }
                        CaptionsGroupHeader(title: String(localized: "Not localized"), count: model.notLocalizedCount) {
                            Button("Add Locales…") { viewModel.openScope() }
                                .buttonStyle(.link)
                                .accessibilityIdentifier("screenshots.captions.addLocales")
                        }
                    } header: {
                        CaptionsColumnHeader(model: model, cellWidth: cellWidth)
                    }
                }
                .frame(width: Self.localeColumnWidth + CGFloat(columnCount) * (cellWidth + 4) + 24, alignment: .leading)
            }
        }
        .background(Palette.content)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Captions by locale and slot"))
        .accessibilityIdentifier("screenshots.captions.table")
    }

    /// The slots, then Search results and Header, then the pages' phrases.
    private var columnCount: Int { model.slotCount + model.artworkRoles.count + model.artworkPhrases.count }

    private func cellWidth(for width: CGFloat) -> CGFloat {
        let available = width - Self.localeColumnWidth - 24 - CGFloat(columnCount) * 4
        return max(Self.minimumCellWidth, (available / CGFloat(max(1, columnCount))).rounded(.down))
    }
}
