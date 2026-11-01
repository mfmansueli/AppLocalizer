//
//  ClaudeCodeLaunchPanel.swift
//  AppLocalizer
//

import SwiftUI

/// In a sheet that asks Claude Code for something (translations, captions,
/// the privacy scan): before it starts, where it starts and what it does;
/// once started, the run, with Show Output over the sheet. The sheet keeps
/// its own Start and Copy Prompt buttons.
struct ClaudeCodeLaunchPanel: View {
    let run: ClaudeCodeRun?
    let appID: StoreApp.ID
    let appName: String
    /// What Claude Code does, e.g. "It translates the missing fields and
    /// proposes them; they wait for you in Review & Push."
    let explanation: String
    /// After Try Again started the new run.
    var onRetried: (ClaudeCodeRun.ID) -> Void = { _ in }
    /// The identifiers' prefix, e.g. "storePage.translate".
    var identifierPrefix = "claudeCode"

    @Environment(ClaudeCodeLauncher.self) private var launcher
    @State private var showsOutput = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if let run {
                Text(explanation)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                ClaudeCodeRunStatusView(run: run, onShowOutput: { showsOutput = true }, onRetried: onRetried)
                Text("Closing this doesn’t stop it.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            } else {
                Label {
                    Text("AppLocalizer starts Claude Code")
                        .font(.headline)
                } icon: {
                    Image(systemName: "bolt.horizontal.circle")
                        .foregroundStyle(Palette.accent)
                }
                Text(explanation)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(folderText)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .sheet(isPresented: $showsOutput) {
            if let run { ClaudeCodeRunOutputSheet(runID: run.id) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(identifierPrefix).launch")
    }

    /// "It runs in ~/Developer/Lumen, with your own login." or, before a
    /// folder is chosen, that it's asked for once.
    private var folderText: String {
        guard let folder = launcher.projectFolder(for: appID) else {
            return String(localized: "AppLocalizer asks for \(appName)’s project folder the first time. Claude Code uses your own login and plan.")
        }
        return String(localized: "It runs in \(ProjectFolderPath.abbreviated(folder)), with your own login and plan.")
    }
}
