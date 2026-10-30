//
//  KeyAssistantSetupTestStep.swift
//  AppLocalizer
//

import SwiftUI

/// Step 4 with a key: one small request (a subtitle, about 400 tokens),
/// its answer and the time it took, and where to use the key.
struct KeyAssistantSetupTestStep: View {
    let viewModel: KeyAssistantSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AppLocalizer sends a small test request to \(viewModel.vendor.title): one subtitle for \(viewModel.appName), in English. Nothing is changed.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            switch viewModel.testState {
            case .idle, .sending:
                box(id: "keySetup.sending") {
                    ProgressView().controlSize(.small)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sending a test request to \(viewModel.vendor.title)…")
                            .font(.callout)
                        Text("About 400 tokens.")
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                }
            case let .works(text):
                box(id: "keySetup.works") {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Palette.positive)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Works")
                            .font(.callout.weight(.semibold))
                        Text(text)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text("Where to use it")
                    .font(.headline)
                    .padding(.top, Spacing.xxSmall)
                VStack(spacing: 0) {
                    place(
                        String(localized: "Store Page → Generate Suggestions…"),
                        String(localized: "What’s New from your commits, promotional text, subtitles, keywords")
                    )
                    Divider()
                    place(
                        String(localized: "Settings → Translation"),
                        viewModel.usesKeyForTranslations ? String(localized: "Uses the same key for translations") : String(localized: "Still uses its own key")
                    )
                }
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
            case let .failed(text):
                box(id: "keySetup.failed") {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Palette.danger)
                        .accessibilityHidden(true)
                    Text(text)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Try Again") { Task { await viewModel.runTest() } }
                        .controlSize(.small)
                }
            }
        }
    }

    private func box(id: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 10, content: content)
            .padding(.horizontal, 14)
            .padding(.vertical, Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(id)
    }

    private func place(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.callout)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(Palette.label2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, Spacing.xSmall)
    }
}
