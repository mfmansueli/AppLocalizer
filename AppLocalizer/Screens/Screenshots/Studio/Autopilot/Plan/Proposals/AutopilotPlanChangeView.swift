//
//  AutopilotPlanChangeView.swift
//  AppLocalizer
//

import SwiftUI

/// One change the assistant sent for this plan outside a run: who and why,
/// each thing it changes with what the plan has now, and Reject or Accept.
struct AutopilotPlanChangeView: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let change: AutopilotPlanChange

    /// One thing it changes: "Streak · steps", now and new.
    private struct Line: Identifiable {
        var id: String
        var title: String
        /// What the plan has now; nil when it has nothing there.
        var now: String?
        var new: String
        var isCode = true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Label(change.client, systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.machineTranslatedMark)
                Text(change.reason ?? String(localized: "Changes for this plan"))
                    .font(.callout.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("autopilot.plan.change.\(change.id).reason")
                HStack(spacing: Spacing.xSmall) {
                    Button("Reject") { studio.rejectPlanChange(change.id) }
                        .accessibilityIdentifier("autopilot.plan.change.\(change.id).reject")
                    Button("Accept") { studio.acceptPlanChange(change.id) }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("autopilot.plan.change.\(change.id).accept")
                }
                .controlSize(.small)
            }
            if let evidence = change.evidence {
                Text(evidence)
                    .font(.caption)
                    .foregroundStyle(Palette.label3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(lines) { line in
                lineView(line)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.change.\(change.id)")
    }

    private func lineView(_ line: Line) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(line.title).font(.caption.weight(.semibold))
            if let now = line.now {
                Text("Now: \(now)")
                    .font(.caption)
                    .foregroundStyle(Palette.label3)
                    .strikethrough()
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(line.new)
                .font(.system(.caption, design: line.isCode ? .monospaced : .default))
                .foregroundStyle(Palette.label2)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Spacing.small)
    }

    private var lines: [Line] {
        var lines = change.screens.map { screen in
            let found = screen.screen(in: plan)
            let device = screen.displayType.map { "\($0.title) · " } ?? ""
            let title = found == nil
                ? device + String(localized: "\(screen.name) · steps · not in this plan, left out")
                : device + String(localized: "\(screen.name) · steps")
            return Line(id: "screen-\(screen.device.mcpValue)-\(screen.screenID)", title: title, now: found.flatMap { nonEmpty($0.steps) }, new: screen.steps)
        }
        if let sampleData = change.sampleData {
            lines.append(Line(id: "sampleData", title: String(localized: "Sample data"), now: nonEmpty(plan.simulator.sampleDataSteps), new: sampleData))
        }
        if let writtenFrom = change.writtenFrom {
            lines.append(Line(id: "writtenFrom", title: String(localized: "Steps written from"), now: plan.writtenFrom.flatMap(nonEmpty), new: writtenFrom))
        }
        if let commands = change.setupCommands {
            lines.append(Line(
                id: "setupCommands", title: String(localized: "Commands added by fixes"),
                now: nonEmpty(plan.simulator.extraCommands.joined(separator: "\n")),
                new: commands.isEmpty ? String(localized: "None: removes them all") : commands.joined(separator: "\n"), isCode: !commands.isEmpty
            ))
        }
        if let notes = change.setupNotes {
            lines.append(Line(
                id: "setupNotes", title: String(localized: "Notes from fixes"),
                now: nonEmpty(plan.simulator.fixNotes.joined(separator: "\n")),
                new: notes.isEmpty ? String(localized: "None: removes them all") : notes.joined(separator: "\n"), isCode: false
            ))
        }
        return lines
    }

    private func nonEmpty(_ text: String) -> String? {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }
}
