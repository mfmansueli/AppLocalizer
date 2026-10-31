//
//  LocaleEditorView.swift
//  AppLocalizer
//

import SwiftUI

/// The locale editor: the primary locale read-only on the left and the
/// chosen locale on the right, field by field, or "Korean has no text yet"
/// for a locale with nothing in it. The locale's suggestions sit above its
/// fields, each one under the field it's for. Languages the app supports
/// and the App Store doesn't have show as a banner on the App Store's
/// languages, a card on their own tab until added, and a note once added.
struct LocaleEditorView: View {
    @Bindable var viewModel: StorePageViewModel

    @Environment(MCPServerController.self) private var assistants
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            LocaleEditorHeader(viewModel: viewModel)
            Divider()
            if let locale = viewModel.editorLocale {
                if viewModel.showsEmptyLocale(locale) {
                    EmptyLocaleView(viewModel: viewModel, locale: locale)
                } else {
                    fields(in: locale)
                }
            } else {
                Spacer()
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toast {
                ActionToast(message: toast) {
                    viewModel.undoToast()
                } onDismiss: {
                    if viewModel.toast == toast { viewModel.toast = nil }
                }
                .padding(.bottom, Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: viewModel.toast)
        .onAppear { viewModel.undoManager = undoManager }
        .onChange(of: undoManager) { viewModel.undoManager = undoManager }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.editor")
    }

    @ViewBuilder
    private func suggestionsPanel(in locale: StoreLocale) -> some View {
        if viewModel.tracksSuggestions {
            SuggestionsPanel(
                appID: viewModel.app.id,
                area: .storePage,
                scopeTitle: locale.name,
                scopes: [.storePage(locale)],
                model: viewModel.suggestionBar(for: locale, assistant: assistants.assistantStatus.clientName),
                filter: $viewModel.suggestionFilter,
                showsOnlyFields: $viewModel.showsOnlySuggestedFields,
                hidesCTA: $viewModel.hidesAssistantCTA,
                requestsAsk: $viewModel.requestsAsk,
                prompt: viewModel.suggestionPrompt,
                generator: viewModel,
                onDismissAll: { viewModel.dismissAllSuggestions(in: locale) },
                onAcceptAll: { viewModel.acceptAllSuggestions(in: locale) },
                onAcceptEverywhere: { viewModel.acceptSuggestionsEverywhere() },
                onRestore: { viewModel.restoreDismissedSuggestions(in: locale) },
                onRequestFinished: { viewModel.toast = ToastMessage(text: $0) }
            )
            .padding(.horizontal, Spacing.large)
            .padding(.top, Spacing.medium)
            .padding(.bottom, Spacing.xSmall)
        }
    }

    /// The project's languages: on an App Store language, the ones to add;
    /// on a suggested one, why and Create Page; on an added one, that its
    /// page comes with the push.
    private func newLanguages(in locale: StoreLocale) -> some View {
        Group {
            if viewModel.isPendingLanguage(locale) {
                NewLanguageCard(
                    title: viewModel.newLanguageTitle(locale),
                    text: viewModel.newLanguageText(locale),
                    onNotNow: { viewModel.declineLanguage(locale) },
                    onCreate: { viewModel.createPage(locale) }
                )
            } else if viewModel.isAddedLanguage(locale) {
                NewLanguageAddedBanner { viewModel.removeLanguage(locale) }
            } else if !viewModel.isNewLanguage(locale), let text = viewModel.newLanguagesBannerText {
                NewLanguagesBanner(
                    text: text,
                    addTitle: viewModel.addAllLanguagesTitle,
                    onReview: { viewModel.presentNewLanguages() },
                    onAddAll: { viewModel.addAllPendingLanguages() }
                )
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.small)
    }

    private func fields(in locale: StoreLocale) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    suggestionsPanel(in: locale)
                    newLanguages(in: locale)
                    ForEach(viewModel.editorFields(in: locale)) { field in
                        EditorFieldRow(viewModel: viewModel, field: field, locale: locale)
                            .id(field)
                        Divider()
                    }
                }
            }
            .task(id: ListingFieldKey(locale, viewModel.editorFocus ?? .name)) {
                guard let field = viewModel.editorFocus else { return }
                await Task.yield()
                proxy.scrollTo(field, anchor: .top)
            }
        }
    }
}
