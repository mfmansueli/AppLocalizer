//
//  StorePageHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The top of the Store Page: what it changes, which version, Ask Claude
/// Code…, Editor or In-App Texts, and the ⋯ menu.
struct StorePageHeader: View {
    @Bindable var viewModel: StorePageViewModel

    /// Editor and In-App Texts; Coverage is in the ⋯ menu and, while it
    /// shows, neither segment is selected.
    private static let modes: [StorePageMode] = [.editor, .inAppTexts]

    var body: some View {
        SectionHeader(
            systemImage: "doc.text",
            tint: Palette.sectionStorePage,
            title: String(localized: "Store Page"),
            subtitle: String(localized: "The words on \(viewModel.app.name)’s App Store page and in search, in every language.")
        ) {
            StorePageVersionMenu(viewModel: viewModel)
            if let version = viewModel.content?.version, !version.isEditable {
                Pill(text: String(localized: "Live · read-only"), systemImage: "lock", style: .outline)
                    .fixedSize()
                    .accessibilityIdentifier("storePage.readOnly")
            }
            if viewModel.isLoaded, viewModel.tracksSuggestions, viewModel.mode != .inAppTexts {
                SuggestionAskButton(
                    appID: viewModel.app.id,
                    area: .storePage,
                    requestsAsk: $viewModel.requestsAsk,
                    prompt: viewModel.suggestionPrompt,
                    generator: viewModel,
                    appName: viewModel.app.name,
                    onRequestFinished: { viewModel.toast = ToastMessage(text: $0) }
                )
            }
            FittingSegmentedPicker(
                label: String(localized: "Store Page views"),
                options: Self.modes.map { ($0, $0.title) },
                selection: $viewModel.mode
            )
            .fixedSize()
            .accessibilityIdentifier("storePage.modePicker")
            if viewModel.isLoaded, !viewModel.showsNoVersionPage {
                StorePageMoreMenu(viewModel: viewModel)
            }
        }
    }
}
