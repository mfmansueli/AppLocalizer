//
//  LocaleEditorView.swift
//  AppLocalizer
//

import SwiftUI

/// The Store Page editor: the language bar, then one card per field with
/// its suggestion inside it and, when there's room, the language's App Store
/// page beside them. Languages the app supports and the App Store doesn't
/// have show as a banner on the App Store's languages, a card on their own
/// tab until added, and a note once added.
struct LocaleEditorView: View {
    @Bindable var viewModel: StorePageViewModel

    /// The window is too narrow for the preview under this.
    private static let previewMinimumWidth: CGFloat = 800

    /// The banners above the fields wrap their text (`fixedSize` vertically)
    /// outside the scroll view, so the window's minimum height is measured
    /// with them. Without a minimum width they're measured nearly 0 wide,
    /// one word a line, and the page grows past the window. The widest
    /// sidebar (360) and this fit the smallest window (860).
    private static let minimumWidth: CGFloat = 500

    @Environment(AppPreferences.self) private var preferences
    /// Nil in previews and scenes without the app's gate.
    @Environment(ProGate.self) private var pro: ProGate?
    @Environment(\.undoManager) private var undoManager
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let model = viewModel.languageBarModel(acceptsRightAway: preferences.acceptsAllWithoutAsking) {
                languageBar(model)
            }
            if let locale = viewModel.editorLocale {
                panel(in: locale)
                if viewModel.showsEmptyLocale(locale) {
                    EmptyLocaleView(viewModel: viewModel, locale: locale)
                } else {
                    HStack(alignment: .top, spacing: Spacing.large) {
                        fields(in: locale)
                        if width >= Self.previewMinimumWidth {
                            StorePagePreviewPane(viewModel: viewModel, locale: locale)
                        }
                    }
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .frame(minWidth: Self.minimumWidth, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
        .onAppear { viewModel.undoManager = undoManager }
        .onChange(of: undoManager) { viewModel.undoManager = undoManager }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.editor")
    }

    private func languageBar(_ model: LanguageBarModel) -> some View {
        LanguageBar(model: model, showsProChip: pro.isFree && model.withSuggestions.count > 1) { locale in
            viewModel.editorLocale = locale
            viewModel.editorFocus = nil
        } onAcceptAll: {
            // One language's suggestions are free with Accept Here too.
            let languages = model.withSuggestions.count
            let accept = { viewModel.acceptAllLanguages(withoutAsking: preferences.acceptsAllWithoutAsking) }
            if languages > 1 {
                pro.require(.acceptAllLanguages(suggestions: model.totalCount, languages: languages), then: accept)
            } else {
                accept()
            }
        } onAcceptHere: {
            viewModel.acceptAllSuggestions(in: model.current)
        } onAskFirst: {
            preferences.acceptsAllWithoutAsking = false
            viewModel.toast = ToastMessage(text: String(localized: "Accept All Languages will show you the suggestions first again."))
        } trailing: {
            if model.currentEntry?.isNewPage == true {
                Pill(text: String(localized: "New page"), style: .accent)
                    .fixedSize()
                    .accessibilityLabel(Text("New, not on the App Store yet"))
                    .accessibilityIdentifier("storePage.editorLocale.new")
            }
            if !viewModel.machineTranslatedFields(in: model.current).isEmpty {
                Button {
                    viewModel.markAllReviewed(in: model.current)
                } label: {
                    Label("Mark All Reviewed", systemImage: "checkmark")
                }
                .accessibilityIdentifier("storePage.markAllReviewed")
            }
        }
    }

    private func panel(in locale: StoreLocale) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if viewModel.tracksSuggestions {
                SuggestionsPanel(
                    appID: viewModel.app.id,
                    area: .storePage,
                    scopes: [.storePage(locale)],
                    hidesCTA: $viewModel.hidesAssistantCTA,
                    appName: viewModel.app.name
                )
            }
            newLanguages(in: locale)
        }
    }

    /// The project's languages: on an App Store language, the ones to add;
    /// on a suggested one, why and Create Page; on an added one, that its
    /// page comes with the push.
    @ViewBuilder
    private func newLanguages(in locale: StoreLocale) -> some View {
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

    private func fields(in locale: StoreLocale) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.editorFields(in: locale)) { field in
                        EditorFieldRow(viewModel: viewModel, field: field, locale: locale)
                            .id(field)
                    }
                }
                .padding(2)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity)
            .task(id: ListingFieldKey(locale, viewModel.editorFocus ?? .name)) {
                guard let field = viewModel.editorFocus else { return }
                await Task.yield()
                proxy.scrollTo(field, anchor: .top)
            }
        }
    }
}
