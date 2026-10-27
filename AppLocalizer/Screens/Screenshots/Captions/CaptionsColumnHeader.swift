//
//  CaptionsColumnHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "Locale", then "1 Today · with subhead", "2 Week"…
struct CaptionsColumnHeader: View {
    let model: CaptionsViewModel
    let cellWidth: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Text("Locale")
                .padding(.leading, Spacing.small)
                .frame(width: CaptionsTable.localeColumnWidth, alignment: .leading)
            ForEach(0..<model.slotCount, id: \.self) { slot in
                let header = model.slotHeader(slot)
                HStack(spacing: 3) {
                    Text("\(slot + 1)")
                        .monospacedDigit()
                        .foregroundStyle(Palette.label2)
                    Text(header.name)
                    if header.hasSubhead {
                        Text("· with subhead")
                    }
                }
                .foregroundStyle(Palette.label3)
                .lineLimit(1)
                .frame(width: cellWidth, alignment: .leading)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.label2)
        .padding(.horizontal, Spacing.medium)
        .frame(height: Metrics.tableHeaderHeight)
        .background(Palette.content)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .combine)
    }
}
