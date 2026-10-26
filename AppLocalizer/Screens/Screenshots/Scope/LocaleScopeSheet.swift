//
//  LocaleScopeSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Which locales get their own screenshots. The rest show the primary
/// locale's set on the App Store; leaving a locale out never deletes what's
/// live there. The footer estimates what a push of the scope costs.
struct LocaleScopeSheet: View {
    @Bindable var viewModel: ScreenshotsViewModel

    var body: some View {
        let primaryName = viewModel.context.primaryLocale.name
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Which locales get their own screenshots?")
                    .font(.title3.weight(.semibold))
                Text("The rest show \(primaryName) screenshots on the App Store. Leaving a locale out never deletes what’s already live there.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                shortcuts(primaryName: primaryName)
                    .padding(.top, Spacing.xSmall)
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.top, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            Divider()
            LocaleScopeTable(viewModel: viewModel)
            Divider()
            footer
        }
        .frame(width: 720, height: 640)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.scope")
    }

    private func shortcuts(primaryName: String) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Button("Locales with Localized Captures") { viewModel.selectLocalesWithCaptures() }
                .accessibilityIdentifier("screenshots.scope.withCaptures")
            Button("All \(viewModel.locales.count)") { viewModel.selectAllLocales() }
                .accessibilityIdentifier("screenshots.scope.all")
            Button("Only \(primaryName)") { viewModel.selectOnlyPrimary() }
                .accessibilityIdentifier("screenshots.scope.onlyPrimary")
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            Text(viewModel.scopeEstimate)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(2)
                .accessibilityIdentifier("screenshots.scope.estimate")
            Spacer(minLength: Spacing.medium)
            Button("Cancel", role: .cancel) { viewModel.scopeDraft = nil }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("screenshots.scope.cancel")
            Button("Save") {
                Task { await viewModel.saveScope() }
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("screenshots.scope.save")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }
}
