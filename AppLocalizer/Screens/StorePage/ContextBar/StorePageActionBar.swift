//
//  StorePageActionBar.swift
//  AppLocalizer
//

import SwiftUI

/// Under the context bar: Translate Missing…, Fill, Import & Export and Add
/// Locale, with the coverage summary line on the right.
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
            Spacer(minLength: Spacing.small)
            Text(viewModel.summaryLine)
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

    private var fillMenu: some View {
        Menu("Fill") {
            Section("Copy from a sibling locale") {
                if viewModel.siblingPairs.isEmpty {
                    Text("Nothing to copy")
                }
                ForEach(viewModel.siblingPairs, id: \.self) { pair in
                    Button("\(pair.source.name) → \(pair.target.name)") {
                        viewModel.copy(pair)
                    }
                }
            }
            Divider()
            Button("Copy URLs to Every Locale") {
                viewModel.copyURLsToEveryLocale()
            }
            .disabled(!viewModel.hasURLsToCopy)
            Button("Send What’s New to Every Locale…") {
                viewModel.presentWhatsNewBroadcast()
            }
            .disabled(viewModel.value(.whatsNew, in: viewModel.listing?.primaryLocale ?? .englishUS).isEmpty)
            Button("Find and Replace…") {
                viewModel.presentFindReplace()
            }
        }
        .fixedSize()
        .accessibilityIdentifier("storePage.fill")
    }

    private var transferMenu: some View {
        Menu("Import & Export") {
            Button("Import Translations…") {
                viewModel.isImporterPresented = true
            }
            Divider()
            Section("For translators") {
                ForEach(ListingTransferFormat.allCases) { format in
                    Button(format.exportTitle) {
                        viewModel.exportFormat = format
                    }
                }
            }
        }
        .fixedSize()
        .accessibilityIdentifier("storePage.importExport")
    }

    private var addLocaleMenu: some View {
        Menu {
            Section("Add a locale") {
                ForEach(viewModel.addableLocales) { locale in
                    Button(locale.name) {
                        viewModel.addLocale(locale)
                    }
                }
            }
        } label: {
            Label("Add Locale", systemImage: "plus")
        }
        .fixedSize()
        .disabled(viewModel.addableLocales.isEmpty)
        .accessibilityIdentifier("storePage.addLocale")
    }
}
