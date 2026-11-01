//
//  AutopilotProblemCard.swift
//  AppLocalizer
//

import SwiftUI

/// A screen the assistant couldn't reach — or the same screen in several
/// languages and devices, for one cause: what happened, the fix it
/// proposes, and the ways out — retry with the fix, reuse the primary
/// language's capture, or upload one by hand. A fix that changes the
/// project (or follows a refused command) is shown as what to change;
/// retrying doesn't add it to the plan, since it isn't a command.
struct AutopilotProblemCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let group: AutopilotProblemGroup

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            (Text(headline).bold() + Text(group.first.what) + Text(" ") + Text(othersText))
                .fixedSize(horizontal: false, vertical: true)
            if group.wasRefused, let command = group.refusedCommand {
                code(command, identifier: "autopilot.problem.refused")
            }
            if let fix = group.proposedFix {
                if group.needsProjectChange {
                    Text("What to change in the project:")
                        .font(.callout.weight(.medium))
                }
                code(fix, identifier: "autopilot.problem.fix")
            }
            HStack(spacing: Spacing.small) {
                Button(retryTitle) {
                    studio.resolve(group, with: .retryWithFix)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("autopilot.problem.retry")
                if !group.includes(locale: run.plan.primaryLocale) {
                    Button("Use the \(primaryName) Capture") { studio.resolve(group, with: .usePrimaryCapture) }
                        .accessibilityIdentifier("autopilot.problem.usePrimary")
                }
                if group.isSingle {
                    Button("Upload One by Hand…") { studio.uploadingProblem = group.first }
                        .accessibilityIdentifier("autopilot.problem.upload")
                }
            }
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(group.wasRefused ? "autopilot.problem.refusedNote" : "autopilot.problem.note")
            }
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.dangerMark, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.problem")
    }

    /// "Week, German: …"; for several, "Styles, 7 languages on iPhone and
    /// iPad: …".
    private var headline: String {
        let place = group.isSingle ? String(localized: "\(screenName), \(language)") : String(localized: "\(screenName), \(languages) on \(devices)")
        return group.wasRefused
            ? String(localized: "\(place): a command wasn’t allowed. ")
            : String(localized: "\(place): couldn’t reach the screen. ")
    }

    /// A change to the project isn't a command, so retrying adds nothing.
    private var retryTitle: String {
        group.proposedFix != nil && !group.needsProjectChange ? String(localized: "Use the Fix and Retry") : String(localized: "Retry")
    }

    private var note: String? {
        if group.wasRefused {
            return String(localized: """
            Claude Code started by AppLocalizer may only run commands that start with xcodebuild, xcrun simctl and the like. \
            Change the project so it doesn’t need this command, then retry, or continue the run in Terminal, where you can allow it.
            """)
        }
        if group.needsProjectChange {
            return String(localized: """
            This is a change to the project, not a command: make it, then retry. Claude Code started by AppLocalizer can’t \
            change files; Claude Code in Terminal can.
            """)
        }
        guard group.proposedFix != nil else { return nil }
        return String(localized: "\(run.client ?? String(localized: "The assistant")) proposed the fix; retrying adds it to the plan so later runs don’t stop here.")
    }

    private func code(_ text: String, identifier: String) -> some View {
        Text(text)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .padding(Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .accessibilityIdentifier(identifier)
    }

    private var screenName: String { run.plan.screen(id: group.screenID)?.name ?? group.screenID }
    private var language: String { Self.name(of: group.first.target.locale) }
    private var primaryName: String { Self.name(of: run.plan.primaryLocale) }

    /// "Korean and German", or "7 languages".
    private var languages: String {
        let locales = group.locales
        guard locales.count > 3 else { return locales.map(Self.name).formatted(.list(type: .and)) }
        return String(localized: "\(locales.count) languages")
    }

    /// "iPhone and iPad".
    private var devices: String { group.displayTypes.map(\.shortTitle).formatted(.list(type: .and)) }

    /// The captures of this screen that wait for the answer, besides the
    /// group's own.
    private var waiting: Int {
        let own = Set(group.problems.map(\.target))
        return run.heldTargets.count { $0.screenID == group.screenID && group.displayTypes.contains($0.displayType) && !own.contains($0) }
    }

    private var othersText: String {
        let others = run.plan.screens.count - 1
        if waiting > 0 {
            return waiting == 1
                ? String(localized: "1 more capture of it waits for your answer; the other screens keep going.")
                : String(localized: "\(waiting) more captures of it wait for your answer; the other screens keep going.")
        }
        return others == 1 ? String(localized: "The other screen and languages keep going.") : String(localized: "The other \(others) screens and languages keep going.")
    }

    private static func name(of code: String) -> String {
        StoreLocaleCatalog.locale(code: code)?.shortName ?? code
    }
}
