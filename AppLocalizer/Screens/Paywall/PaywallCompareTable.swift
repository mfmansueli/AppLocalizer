//
//  PaywallCompareTable.swift
//  AppLocalizer
//

import SwiftUI

/// Compare Free and Pro: one row for each feature.
struct PaywallCompareTable: View {
    var rows = ProComparisonRow.all

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                cell("", isHeader: true)
                cell(String(localized: "Free"), isHeader: true)
                cell(String(localized: "Pro"), isHeader: true)
            }
            .background(Palette.fill1)
            ForEach(rows) { row in
                Divider().gridCellColumns(3)
                GridRow {
                    cell(row.feature)
                    cell(row.free, color: row.isMissingInFree ? Palette.label3 : Palette.label)
                    cell(row.pro, weight: .semibold)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Free and Pro"))
        .accessibilityIdentifier("paywall.compare")
    }

    private func cell(_ text: String, isHeader: Bool = false, color: Color = Palette.label, weight: Font.Weight = .regular) -> some View {
        Text(text)
            .font(isHeader ? .system(size: 11.5, weight: .bold) : .system(size: 12, weight: weight))
            .foregroundStyle(isHeader ? Palette.label2 : color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.small + 2)
            .padding(.vertical, Spacing.xSmall + 1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PaywallCompareTable().padding().frame(width: 480)
}
