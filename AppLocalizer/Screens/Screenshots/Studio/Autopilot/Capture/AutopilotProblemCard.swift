//
//  AutopilotProblemCard.swift
//  AppLocalizer
//

import SwiftUI

/// A screen the assistant couldn't reach: what happened, the fix it
/// proposes, and the ways out — retry with the fix, reuse the primary
/// language's capture, or upload one by hand.
struct AutopilotProblemCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let problem: AutopilotProblem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            (Text("\(screenName), \(language): couldn’t reach the screen. ").bold() + Text(problem.what) + Text(" ") + Text(othersText))
                .fixedSize(horizontal: false, vertical: true)
            if let fix = problem.proposedFix, !fix.isEmpty {
                Text(fix)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(Spacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                    .accessibilityIdentifier("autopilot.problem.fix")
            }
            HStack(spacing: Spacing.small) {
                Button(problem.proposedFix?.isEmpty == false ? String(localized: "Use the Fix and Retry") : String(localized: "Retry")) {
                    studio.resolve(problem, with: .retryWithFix)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("autopilot.problem.retry")
                if problem.target.locale != run.plan.primaryLocale {
                    Button("Use the \(primaryName) Capture") { studio.resolve(problem, with: .usePrimaryCapture) }
                        .accessibilityIdentifier("autopilot.problem.usePrimary")
                }
                Button("Upload One by Hand…") { studio.uploadingProblem = problem }
                    .accessibilityIdentifier("autopilot.problem.upload")
            }
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            if problem.proposedFix?.isEmpty == false {
                Text("\(run.client ?? String(localized: "The assistant")) proposed the fix; retrying adds it to the plan so later runs don’t stop here.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.dangerMark, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.problem")
    }

    private var screenName: String { run.plan.screen(id: problem.target.screenID)?.name ?? problem.target.screenID }
    private var language: String { StoreLocaleCatalog.locale(code: problem.target.locale)?.shortName ?? problem.target.locale }
    private var primaryName: String { StoreLocaleCatalog.locale(code: run.plan.primaryLocale)?.shortName ?? run.plan.primaryLocale }

    private var othersText: String {
        let others = run.plan.screens.count - 1
        return others == 1 ? String(localized: "The other screen and languages keep going.") : String(localized: "The other \(others) screens and languages keep going.")
    }
}
