//
//  AutopilotStallNotice.swift
//  AppLocalizer
//

import SwiftUI

/// Capture or Design, when nobody is working on the run although the
/// assistant has work: why (Claude Code ended and what it last said,
/// AppLocalizer was closed, or nothing has arrived for a while), with
/// Continue, which starts Claude Code where the run stopped, or copies the
/// prompt that does. Only a stop or a silence is drawn as a warning.
struct AutopilotStallNotice: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let stall: AutopilotStall
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    @State private var showsOutput = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(stall.headline(of: run, now: studio.autopilot?.now() ?? .now))
                .bold()
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.stall.text")
            if case let .ended(words?) = stall, !words.isEmpty {
                Text("It said: “\(words)”")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(4)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("autopilot.stall.lastWords")
            }
            HStack(spacing: Spacing.small) {
                Button(canStart ? String(localized: "Continue") : String(localized: "Copy the Prompt to Continue")) {
                    studio.continueRun()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("autopilot.stall.continue")
                if let session = studio.launchedRun {
                    Button("Show Output") { showsOutput = true }
                        .accessibilityIdentifier("autopilot.stall.output")
                        .sheet(isPresented: $showsOutput) { ClaudeCodeRunOutputSheet(runID: session.id) }
                }
            }
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            Text(note)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.stall.note")
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(stall.isWarning ? Palette.warningMark : Palette.separator, lineWidth: stall.isWarning ? 1 : 0.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.stall")
    }

    private var canStart: Bool { launcher?.canStart == true }

    private var note: String {
        if canStart { return AutopilotStall.continueNote(for: run) }
        return studio.didCopyPrompt
            ? String(localized: "Copied. Paste it into Claude Code in the app’s folder.")
            : String(localized: "Copies the prompt that continues the run: paste it into Claude Code in the app’s folder.")
    }
}
