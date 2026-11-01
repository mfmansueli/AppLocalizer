//
//  AssistantSetupLaunchStep.swift
//  AppLocalizer
//

import SwiftUI

/// Step 3 when AppLocalizer starts Claude Code: Install Helper… until the
/// helper is saved and finds Claude Code, then the app's project folder,
/// suggested from where Claude Code worked last.
struct AssistantSetupLaunchStep: View {
    let viewModel: AssistantSetupViewModel
    let launcher: ClaudeCodeLauncher

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let installation = launcher.helper.installation {
                installed(installation)
                folder
            } else {
                install
            }
        }
    }

    // MARK: - Helper

    private var install: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if launcher.helper != .notInstalled, launcher.helper != .unknown {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(launcher.helper.title)
                            .font(.callout.weight(.semibold))
                        Text(launcher.helper.detail)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Palette.warning)
                }
                .accessibilityIdentifier("assistantSetup.launch.helperState")
            }
            HStack(spacing: Spacing.small) {
                if let title = launcher.helper.installTitle {
                    Button(title) { Task { await launcher.installHelper() } }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("assistantSetup.launch.install")
                    Text("Opens a Save panel in the right folder. Just click Save.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                } else {
                    Button("Check Again") { Task { await launcher.refreshHelper() } }
                        .accessibilityIdentifier("assistantSetup.launch.check")
                }
            }
            if let error = launcher.installError {
                InlineMessage.error(error)
                    .font(.caption)
            }
            Text("macOS runs the helper outside AppLocalizer’s sandbox, and only when you start something here. Delete it from the folder any time.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
    }

    private func installed(_ installation: ClaudeCodeInstallation) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.positive)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.small) {
                    Text("Helper installed")
                        .font(.callout.weight(.semibold))
                    Text(installation.title)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                Text(installation.displayPath())
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("assistantSetup.launch.installed")
    }

    // MARK: - Folder

    private var folder: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("\(viewModel.appName)’s project folder")
                .font(.headline)
            HStack(spacing: Spacing.small) {
                Image(systemName: "folder")
                    .foregroundStyle(Palette.label2)
                    .accessibilityHidden(true)
                Text(viewModel.projectFolder.map { ProjectFolderPath.abbreviated($0) } ?? String(localized: "Not chosen yet"))
                    .font(.callout.monospaced())
                    .foregroundStyle(viewModel.projectFolder == nil ? Palette.label2 : Palette.label)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("assistantSetup.launch.folder")
                Button(viewModel.projectFolder == nil ? String(localized: "Choose…") : String(localized: "Change…")) {
                    viewModel.chooseProjectFolder()
                }
                .controlSize(.small)
                .accessibilityIdentifier("assistantSetup.launch.chooseFolder")
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, 10)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            Text("Claude Code starts here, so it can read the code and git history. It never writes to the project, and it can’t push to App Store Connect.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
