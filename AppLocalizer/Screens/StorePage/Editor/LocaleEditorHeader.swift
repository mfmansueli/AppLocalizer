//
//  LocaleEditorHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The editor's bar: which locale is on the left, the locale picker with
/// ‹ › to step through locales (the App Store page's, then the new ones the
/// app supports), "New" and "Right to left", and Mark All Reviewed when the
/// locale has machine-translated fields.
struct LocaleEditorHeader: View {
    @Bindable var viewModel: StorePageViewModel

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            if let primary = viewModel.listing?.primaryLocale {
                Text("\(primary.name) · primary · read-only")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                viewModel.stepEditorLocale(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Previous locale"))
            Picker("Locale to edit", selection: $viewModel.editorLocale) {
                ForEach(viewModel.appStoreEditorLocales) { locale in
                    item(locale, isNew: false)
                }
                let new = viewModel.newEditorLocales
                if !new.isEmpty {
                    Section("Not on the App Store yet") {
                        ForEach(new) { locale in
                            item(locale, isNew: true)
                        }
                    }
                }
            }
            .labelsHidden()
            .frame(width: 160)
            .accessibilityIdentifier("storePage.editorLocale")
            Button {
                viewModel.stepEditorLocale(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Next locale"))
            HStack(spacing: Spacing.xSmall) {
                if let locale = viewModel.editorLocale, viewModel.isNewLanguage(locale) {
                    Pill(text: String(localized: "New"), style: .outline)
                        .accessibilityLabel(Text("New, not on the App Store yet"))
                        .accessibilityIdentifier("storePage.editorLocale.new")
                }
                if viewModel.editorLocale?.isRTL == true {
                    Pill(text: String(localized: "Right to left"), style: .outline)
                }
                Spacer(minLength: 0)
                if let locale = viewModel.editorLocale, !viewModel.machineTranslatedFields(in: locale).isEmpty {
                    Button {
                        viewModel.markAllReviewed(in: locale)
                    } label: {
                        Label("Mark All Reviewed", systemImage: "checkmark")
                    }
                    .accessibilityIdentifier("storePage.markAllReviewed")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.small)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
    }

    private func item(_ locale: StoreLocale, isNew: Bool) -> some View {
        let count = viewModel.suggestionCount(in: locale)
        let coming = viewModel.comingCount(in: locale)
        return Text(Self.localeTitle(locale, count: count, coming: coming, isNew: isNew))
            .accessibilityLabel(Text(Self.localeAccessibilityLabel(locale, count: count, coming: coming, isNew: isNew)))
            .tag(Optional(locale))
    }

    /// "German · 2", with "· 1 coming" while Suggest Everything owes it
    /// more; "Polish · New · 8" for a language not on the App Store yet.
    static func localeTitle(_ locale: StoreLocale, count: Int, coming: Int, isNew: Bool = false) -> String {
        var title = isNew ? "\(locale.name) · " + String(localized: "New") : locale.name
        if count > 0 { title += " · \(count)" }
        if coming > 0 { title += " · " + String(localized: "\(coming) coming") }
        return title
    }

    private static func localeAccessibilityLabel(_ locale: StoreLocale, count: Int, coming: Int, isNew: Bool) -> String {
        var parts = [locale.name]
        if isNew { parts.append(String(localized: "new, not on the App Store yet")) }
        if count > 0 { parts.append(String(localized: "\(count) suggestions")) }
        if coming > 0 { parts.append(String(localized: "\(coming) coming")) }
        return parts.joined(separator: ", ")
    }
}
