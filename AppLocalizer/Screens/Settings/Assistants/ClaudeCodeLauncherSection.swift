//
//  ClaudeCodeLauncherSection.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → AI Assistants' "Start Claude Code from AppLocalizer": the
/// helper (install, check again, show it in Finder), each app's project
/// folder, and what a run may do.
struct ClaudeCodeLauncherSection: View {
    @Environment(ClaudeCodeLauncher.self) private var launcher
    @Environment(MCPServerController.self) private var server
    /// The library's apps, when the main window has loaded them.
    @State private var libraryApps: [StoreApp] = []

    var body: some View {
        Section {
            helperRow
            ForEach(apps, id: \.id) { app in
                folderRow(id: app.id, name: app.name)
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("What a run may do")
                ForEach([ClaudeCodePermissions.readProject, .autopilot], id: \.title) { permissions in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                        Text(permissions.title)
                            .font(.caption.weight(.semibold))
                            .frame(width: 210, alignment: .leading)
                        Text(permissions.detail)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityIdentifier("settings.ai.launch.permissions")
        } header: {
            Text("Start Claude Code from AppLocalizer")
        } footer: {
            Text("""
            Anything else is refused and shown in the run’s output. Each run gets its own token, which stops working when it \
            ends. Claude Code uses your own login and plan.
            """)
            .font(.callout)
            .foregroundStyle(Palette.label2)
        }
        .task { await loadApps() }
    }

    // MARK: - Helper

    private var helperRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: launcher.canStart ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(launcher.canStart ? Palette.positive : Palette.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(launcher.helper.title)
                    .accessibilityIdentifier("settings.ai.launch.helper")
                if !launcher.helper.detail.isEmpty {
                    Text(launcher.helper.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let error = launcher.installError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Palette.danger)
                }
            }
            Spacer()
            if let title = launcher.helper.installTitle {
                Button(title) { Task { await launcher.installHelper() } }
                    .accessibilityIdentifier("settings.ai.launch.install")
            }
            if launcher.helper.isInstalled {
                Button("Check Again") { Task { await launcher.refreshHelper() } }
                    .accessibilityIdentifier("settings.ai.launch.check")
                Button("Show in Finder") { ClaudeCodeHelperInstaller.reveal() }
                    .accessibilityIdentifier("settings.ai.launch.reveal")
            }
        }
    }

    // MARK: - Folders

    /// The library's apps, else the ones a run or a folder was for.
    private var apps: [(id: StoreApp.ID, name: String)] {
        var apps = libraryApps.map { (id: $0.id, name: $0.name) }
        for known in launcher.knownApps where !apps.contains(where: { $0.id == known.id }) {
            apps.append(known)
        }
        return apps
    }

    private func folderRow(id: StoreApp.ID, name: String) -> some View {
        let folder = launcher.projectFolder(for: id)
        return HStack(spacing: Spacing.small) {
            Text(name)
                .frame(width: 160, alignment: .leading)
                .lineLimit(1)
            Text(folder.map { ProjectFolderPath.abbreviated($0) } ?? String(localized: "Asked the first time it starts"))
                .font(folder == nil ? .callout : .callout.monospaced())
                .foregroundStyle(folder == nil ? Palette.label2 : Palette.label)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(folder == nil ? String(localized: "Choose…") : String(localized: "Change…")) {
                launcher.chooseProjectFolder(for: id, appName: name)
            }
            .accessibilityIdentifier("settings.ai.launch.folder.\(id)")
        }
        .accessibilityElement(children: .contain)
        .contextMenu {
            if folder != nil {
                Button("Forget Folder") { launcher.setProjectFolder(nil, for: id) }
            }
        }
    }

    private func loadApps() async {
        guard let workspace = server.workspace, let apps = try? await workspace.apps() else { return }
        libraryApps = apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
