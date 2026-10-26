//
//  SetsColumnHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The matrix's pinned header: Locale, Preview and the numbered slots; on
/// iPhone the first three carry a magnifying glass, since they also show in
/// search results.
struct SetsColumnHeader: View {
    let columns: SetsColumns
    let slots: [(index: Int, name: String)]
    let showsInSearch: (Int) -> Bool
    let stickyOffset: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text("Locale")
                .frame(width: SetsColumns.locale, alignment: .leading)
                .padding(.leading, SetsColumns.leading)
                .background(Palette.content)
                .offset(x: stickyOffset)
                .zIndex(1)
            Text("Preview")
                .frame(width: SetsColumns.preview)
            ForEach(slots, id: \.index) { slot in
                slotTitle(slot)
                    .frame(width: columns.slot)
            }
            Spacer(minLength: 0)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.label2)
        .frame(height: 30)
        .background(Palette.content)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.sets.header")
    }

    private func slotTitle(_ slot: (index: Int, name: String)) -> some View {
        HStack(spacing: 3) {
            Text(verbatim: "\(slot.index + 1)")
                .foregroundStyle(Palette.label)
            Text(slot.name)
                .foregroundStyle(Palette.label3)
            if showsInSearch(slot.index) {
                Image(systemName: "magnifyingglass")
                    .imageScale(.small)
                    .accessibilityLabel(Text("Shows in search results"))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }
}
