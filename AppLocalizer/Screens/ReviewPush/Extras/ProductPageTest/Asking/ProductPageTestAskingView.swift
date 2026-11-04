//
//  ProductPageTestAskingView.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// While the sheet waits for the variant: how long it's been, each step
/// (asked, read, designing, rendering in every language) done or going on,
/// the Claude Code AppLocalizer started for it with its latest step, the
/// few before it, Show Output and Stop, and when nobody's working on it,
/// Start Claude Code Again (or the prompt to paste).
struct ProductPageTestAskingView: View {
    let model: ProductPageTestModel
    let center: AutopilotCenter?

    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?
    @State private var showsOutput = false
    @State private var copiedPrompt = false

    /// The steps before the latest one the strip shows.
    private static let earlierStepCount = 4

    var body: some View {
        let run = center?.run(for: model.plan.appID)
        let session = model.session(in: launcher, run: run)
        VStack(alignment: .leading, spacing: Spacing.small) {
            header(run)
            steps(model.steps(of: run))
            if let session {
                ClaudeCodeRunStatusView(
                    run: session, onShowOutput: { showsOutput = true }, onRetried: { model.launchedRunID = $0 },
                    onDismiss: { model.launchedRunID = nil }
                )
                if session.isActive { earlierSteps(session) }
            }
            if model.isIdle(session: session, run: run, canStart: launcher?.canStart == true) {
                idle(session)
            } else if launcher?.canStart != true, let run, run.variantRequest?.receivedAt == nil {
                copyPrompt(run)
            }
        }
        .sheet(isPresented: $showsOutput) {
            if let session { ClaudeCodeRunOutputSheet(runID: session.id) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ppo.waiting")
    }

    /// "Claude Code is making the Outcome variant" and how long since it
    /// was asked for.
    private func header(_ run: AutopilotRun?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text("\(model.assistantName ?? run?.client ?? String(localized: "The assistant")) is making the \(model.treatmentName) variant")
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("ppo.waiting.title")
            if let askedAt = run?.variantRequest?.askedAt {
                TimelineView(.periodic(from: askedAt, by: 1)) { context in
                    Text(ClaudeCodeRunStatusView.duration(context.date.timeIntervalSince(askedAt)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Palette.label2)
                }
                .help(Text("Since it was asked for"))
                .accessibilityLabel(Text("Waiting"))
            }
        }
    }

    private func steps(_ steps: [ProductPageTestAskingStep]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(steps) { step in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    icon(step.state)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.title)
                            .font(.callout.weight(step.state == .current ? .medium : .regular))
                            .foregroundStyle(step.state == .upcoming ? Palette.label2 : Palette.label)
                        if let detail = step.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                // The state leads the label: macOS drops a value set on a group.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(Self.accessibilityLabel(of: step)))
                .accessibilityIdentifier("ppo.step.\(step.id)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ppo.steps")
    }

    /// "Done: Claude Code read what to change, 15:12".
    static func accessibilityLabel(of step: ProductPageTestAskingStep) -> String {
        let text = [step.title, step.detail].compactMap(\.self).joined(separator: ", ")
        return "\(stateTitle(step.state)): \(text)"
    }

    @ViewBuilder
    private func icon(_ state: ProductPageTestAskingStep.State) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.positive)
        case .current:
            ProgressView().controlSize(.mini)
        case .upcoming:
            Image(systemName: "circle").foregroundStyle(Palette.label3)
        }
    }

    private static func stateTitle(_ state: ProductPageTestAskingStep.State) -> String {
        switch state {
        case .done: String(localized: "Done")
        case .current: String(localized: "In progress")
        case .upcoming: String(localized: "Not yet")
        }
    }

    /// The steps before the one the strip shows, newest last.
    @ViewBuilder
    private func earlierSteps(_ session: ClaudeCodeRun) -> some View {
        let steps = session.activity.filter { $0.kind != .started }.dropLast().suffix(Self.earlierStepCount)
        if !steps.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text("Before that")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                ForEach(Array(steps)) { step in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                        Image(systemName: step.systemImage)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .frame(width: 14)
                            .accessibilityHidden(true)
                        Text(step.kind == .appLocalizer ? String(localized: "AppLocalizer · \(step.text)") : step.text)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(step.date.formatted(date: .omitted, time: .standard))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Palette.label3)
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ppo.earlierSteps")
        }
    }

    /// Claude Code stopped, or was stopped, before sending the variant.
    private func idle(_ session: ClaudeCodeRun?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(session == nil
                ? String(localized: "Nobody is working on the variant right now.")
                : String(localized: "Claude Code stopped before sending the variant. The request is still open."))
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Start Claude Code Again") {
                Task { await model.continueAsking(center: center, launcher: launcher) }
            }
            .controlSize(.small)
            .accessibilityIdentifier("ppo.startAgain")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ppo.idle")
    }

    /// Without the helper: the prompt that continues the run, to paste in
    /// the assistant.
    private func copyPrompt(_ run: AutopilotRun) -> some View {
        Button(copiedPrompt ? String(localized: "Copied") : String(localized: "Copy Prompt")) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(AutopilotPrompt.continuing(run, appName: model.plan.appName), forType: .string)
            copiedPrompt = true
        }
        .controlSize(.small)
        .help(Text("The prompt that continues \(model.plan.appName)’s run, to paste in your assistant"))
        .accessibilityIdentifier("ppo.copyPrompt")
    }
}
