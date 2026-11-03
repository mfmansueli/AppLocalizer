//
//  AutopilotArtworkBriefBox.swift
//  AppLocalizer
//

import SwiftUI

/// Design's "What AppLocalizer asks Claude Design for the header and
/// search artwork": the brief's rules, one a row, as `get_design_brief`
/// sends them.
struct AutopilotArtworkBriefBox: View {
    let run: AutopilotRun

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What AppLocalizer asks \(designer) for the header and search artwork")
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(Palette.fill1)
                .accessibilityAddTraits(.isHeader)
            ForEach(AutopilotArtworkBrief(run.plan.alsoMakes).rows) { row in
                Divider()
                HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                    Text(row.title)
                        .font(.callout.weight(.semibold))
                        .frame(width: 150, alignment: .leading)
                    Text(row.text)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, 7)
                .accessibilityElement(children: .combine)
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.design.artworkBrief")
    }

    /// Who designs from it: Claude Code that AppLocalizer started, else the
    /// design source.
    private var designer: String {
        run.startsClaudeCode == true ? (run.client ?? String(localized: "Claude Code")) : run.designKind.title
    }
}
