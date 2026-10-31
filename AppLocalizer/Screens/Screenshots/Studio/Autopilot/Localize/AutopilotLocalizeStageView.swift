//
//  AutopilotLocalizeStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Localize and check: each language as AppLocalizer renders and checks
/// it, with what was shortened.
struct AutopilotLocalizeStageView: View {
    let run: AutopilotRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Localize and check").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(run.checkedScreenshots) of \(run.totalScreenshots)")
                        .monospacedDigit()
                        .foregroundStyle(Palette.label2)
                }
                ProgressView(value: Double(run.checkedScreenshots), total: Double(max(run.totalScreenshots, 1)))
                VStack(spacing: 0) {
                    ForEach(Array(run.plan.localeCodes.enumerated()), id: \.element) { index, code in
                        if index > 0 { Divider() }
                        AutopilotLocaleRow(run: run, code: code)
                    }
                }
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.localize")
    }
}
