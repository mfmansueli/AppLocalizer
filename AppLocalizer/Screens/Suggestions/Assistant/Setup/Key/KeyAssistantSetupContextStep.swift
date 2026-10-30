//
//  KeyAssistantSetupContextStep.swift
//  AppLocalizer
//

import SwiftUI

/// Step 3 with a key: what each request may include. App Store Connect's
/// text always goes; the project folder's commits and changelog (read on
/// this Mac) and the latest reviews only when switched on. Source code
/// never goes.
struct KeyAssistantSetupContextStep: View {
    @Bindable var viewModel: KeyAssistantSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(viewModel.vendor.title) only sees what AppLocalizer sends with each request. Before each one, you see the list.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 0) {
                row(
                    String(localized: "App Store Connect text"),
                    String(localized: "The fields you ask about in every language, with their limits and the last version’s values.")
                ) {
                    Text("Always")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                Divider()
                row(
                    String(localized: "Project folder"),
                    String(localized: "Commit messages since the last release tag, and CHANGELOG.md. Read on this Mac; only those excerpts are sent."),
                    path: true
                ) {
                    Toggle("Project folder", isOn: Binding(get: { viewModel.readsProjectFolder }, set: setReadsFolder))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityIdentifier("keySetup.folder")
                }
                Divider()
                row(String(localized: "Customer reviews"), String(localized: "The latest App Store reviews, to learn what people praise.")) {
                    Toggle("Customer reviews", isOn: $viewModel.readsReviews)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityIdentifier("keySetup.reviews")
                }
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
            InlineMessage(
                text: String(localized: """
                Source code is never sent. Without it, App Review notes and category checks need an assistant that reads \
                the project itself, like Claude Code.
                """),
                systemImage: "info.circle",
                tint: Palette.label2
            )
            .font(.caption)
        }
    }

    private func row(_ title: String, _ detail: String, path: Bool = false, @ViewBuilder trailing: () -> some View) -> some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if path {
                    HStack(spacing: Spacing.small) {
                        Text(viewModel.projectFolderPath ?? String(localized: "No folder chosen"))
                            .font(.caption.monospaced())
                            .foregroundStyle(viewModel.projectFolder == nil ? Palette.label3 : Palette.label)
                            .accessibilityIdentifier("keySetup.folderPath")
                        Button("Choose…", action: chooseFolder)
                            .controlSize(.small)
                            .accessibilityIdentifier("keySetup.chooseFolder")
                    }
                    .padding(.top, Spacing.xxSmall)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// On without a folder asks for one first.
    private func setReadsFolder(_ isOn: Bool) {
        if isOn, viewModel.projectFolder == nil { chooseFolder() }
        viewModel.readsProjectFolder = isOn && viewModel.projectFolder != nil
    }

    private func chooseFolder() {
        guard let url = ProjectFolderPicker.choose() else { return }
        viewModel.projectFolder = url
        viewModel.readsProjectFolder = true
    }
}
