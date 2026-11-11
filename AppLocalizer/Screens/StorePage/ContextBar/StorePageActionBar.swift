//
//  StorePageActionBar.swift
//  AppLocalizer
//

import SwiftUI

/// Under the context bar: Translate Missing…, Fill, Import & Export and Add
/// Locale (the languages the app supports first), plus Ask Claude Code… on
/// In-App Texts, with the coverage summary line on the right.
struct StorePageActionBar: View {
    let viewModel: StorePageViewModel

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Button {
                viewModel.presentTranslate()
            } label: {
                Label("Translate Missing…", systemImage: "globe")
            }
            .buttonStyle(.borderedProminent)
            .help(Text("Translate missing fields (⇧⌘T)"))
            .accessibilityIdentifier("storePage.translateMissing")
            fillMenu
            transferMenu
            addLocaleMenu
            if viewModel.mode == .inAppTexts {
                InAppTextsAskButton(app: viewModel.app)
            }
            Spacer(minLength: Spacing.small)
            Text(summaryLine)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityIdentifier("storePage.summary")
        }
        .controlSize(.small)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }

    /// The grid's own counts on In-App Texts, the store page's otherwise.
    private var summaryLine: String {
        guard viewModel.mode == .inAppTexts else { return viewModel.summaryLine }
        return viewModel.inAppTexts.matrix?.summaryLine ?? ""
    }

    private var fillMenu: some View {
        Menu("Fill") {
            StorePageFillItems(viewModel: viewModel)
        }
        .fixedSize()
        .accessibilityIdentifier("storePage.fill")
    }

    private var transferMenu: some View {
        Menu("Import & Export") {
            StorePageTransferItems(viewModel: viewModel)
        }
        .fixedSize()
        .accessibilityIdentifier("storePage.importExport")
    }

    private var addLocaleMenu: some View {
        Menu {
            StorePageAddLocaleItems(viewModel: viewModel)
        } label: {
            Label("Add Locale", systemImage: "plus")
        }
        .fixedSize()
        .disabled(viewModel.addableLocales.isEmpty)
        .accessibilityIdentifier("storePage.addLocale")
    }
}
