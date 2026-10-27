//
//  LocaleEditorView.swift
//  AppLocalizer
//

import SwiftUI

/// The locale editor: the primary locale read-only on the left and the
/// chosen locale on the right, field by field, or "Korean has no text yet"
/// for a locale with nothing in it.
struct LocaleEditorView: View {
    @Bindable var viewModel: StorePageViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            LocaleEditorHeader(viewModel: viewModel)
            Divider()
            if let locale = viewModel.editorLocale {
                if viewModel.isEmptyLocale(locale) {
                    EmptyLocaleView(viewModel: viewModel, locale: locale)
                } else {
                    fields(in: locale)
                }
            } else {
                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.editor")
    }

    private func fields(in locale: StoreLocale) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.listing?.fields ?? []) { field in
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
