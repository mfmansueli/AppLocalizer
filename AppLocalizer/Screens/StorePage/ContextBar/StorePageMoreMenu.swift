//
//  StorePageMoreMenu.swift
//  AppLocalizer
//

import SwiftUI

/// The header's ⋯: Coverage, the tools that apply to every language, and
/// the less-used suggestion controls.
struct StorePageMoreMenu: View {
    @Bindable var viewModel: StorePageViewModel

    @Environment(MCPServerController.self) private var assistants

    var body: some View {
        Menu {
            Button("Coverage") {
                viewModel.mode = .coverage
            }
            .accessibilityIdentifier("storePage.more.coverage")
            if viewModel.isVersionEditable {
                Divider()
                Button("Translate Missing…") {
                    viewModel.presentTranslate()
                }
                .accessibilityIdentifier("storePage.more.translate")
                Menu("Fill") {
                    StorePageFillItems(viewModel: viewModel)
                }
                Menu("Import & Export") {
                    StorePageTransferItems(viewModel: viewModel)
                }
                Menu("Add Locale") {
                    StorePageAddLocaleItems(viewModel: viewModel)
                }
                .disabled(viewModel.addableLocales.isEmpty)
            }
            if viewModel.mode == .editor, viewModel.tracksSuggestions, let locale = viewModel.editorLocale {
                Divider()
                SuggestionsMenuItems(
                    model: viewModel.suggestionBar(for: locale, assistant: assistants.assistantStatus.clientName),
                    filter: $viewModel.suggestionFilter,
                    showsOnlyFields: $viewModel.showsOnlySuggestedFields,
                    onDismissAll: { viewModel.dismissAllSuggestions(in: locale) },
                    onRestore: { viewModel.restoreDismissedSuggestions(in: locale) }
                )
            }
        } label: {
            Label("More", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityIdentifier("storePage.more")
    }
}
