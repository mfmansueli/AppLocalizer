//
//  AutopilotWaitStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Capture, before the assistant picks the plan up: the Claude Code run
/// AppLocalizer started, or the prompt to paste, copied already, and the
/// shortcut.
struct AutopilotWaitStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let client: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Capture").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
            if let launched = studio.launchedRun {
                Text("""
                AppLocalizer started Claude Code in \(launched.displayDirectory). It builds \(studio.app.name), boots the \
                simulators and sends each capture back; the stages move on as they arrive.
                """)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                AutopilotLaunchStatus(studio: studio, run: launched)
                Spacer()
            } else {
                pasted
            }
        }
        .padding(Spacing.xLarge)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.wait")
    }

    private var pasted: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Paste this into \(name). AppLocalizer can’t start it: the assistant asks for each step.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
            Text(studio.prompt)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
                .accessibilityIdentifier("autopilot.wait.prompt")
            HStack(spacing: Spacing.small) {
                if studio.didCopyPrompt {
                    Label {
                        Text("Copied. Shortcut in Claude Code: \(Text(ScreenshotStudioModel.promptShortcut).font(.system(.callout, design: .monospaced)))")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.positive)
                    }
                    .font(.callout)
                    .accessibilityIdentifier("autopilot.wait.copied")
                }
                Spacer()
                Button("Copy Again") { studio.copyPrompt() }
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("autopilot.wait.copy")
            }
            ClaudeCodeLaunchHint(client: name)
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text("Waiting for \(name) to pick up the plan…")
                    .foregroundStyle(Palette.label2)
            }
            .padding(.top, Spacing.medium)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("autopilot.wait.spinner")
            Spacer()
        }
    }

    private var name: String { client ?? String(localized: "your assistant") }
}
