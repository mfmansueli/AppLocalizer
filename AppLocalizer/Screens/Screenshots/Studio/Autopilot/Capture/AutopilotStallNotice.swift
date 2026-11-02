//
//  AutopilotStallNotice.swift
//  AppLocalizer
//

import SwiftUI

/// Capture, when nobody is working on the run although captures are left:
/// why (Claude Code ended and what it last said, AppLocalizer was closed,
/// or nothing has arrived for a while), with Continue, which starts Claude
/// Code where the run stopped, or copies the prompt that does.
struct AutopilotStallNotice: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let stall: AutopilotStall
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    @State private var showsOutput = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(headline)
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
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.warningMark, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.stall")
    }

    private var canStart: Bool { launcher?.canStart == true }

    /// "Claude Code stopped with 113 captures left."
    private var headline: String {
        let left = run.capturesLeft
        switch stall {
        case .ended:
            return left == 1
                ? String(localized: "Claude Code stopped with 1 capture left.")
                : String(localized: "Claude Code stopped with \(left) captures left.")
        case .notRunning:
            return String(localized: "Claude Code isn’t running for this run any more: AppLocalizer was closed. \(left) captures are left.")
        case let .quiet(since):
            let minutes = max(Int((studio.autopilot?.now() ?? .now).timeIntervalSince(since) / 60), 1)
            return String(localized: "Nothing has arrived for \(minutes) minutes, with \(left) captures left. If Claude Code stopped, continue it here.")
        }
    }

    private var note: String {
        if canStart {
            return String(localized: """
            Continue starts Claude Code again where the run is: what’s captured stays, and a device this Mac can’t run \
            becomes one problem for the device, so the rest goes on.
            """)
        }
        return didCopy
            ? String(localized: "Copied. Paste it into Claude Code in the app’s folder.")
            : String(localized: "Copies the prompt that continues the run: paste it into Claude Code in the app’s folder.")
    }

    private var didCopy: Bool { studio.didCopyPrompt }
}
