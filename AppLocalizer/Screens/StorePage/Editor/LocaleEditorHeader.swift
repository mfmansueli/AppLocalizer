//
//  LocaleEditorHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The editor's bar: which locale is on the left, the locale picker with
/// ‹ › to step through locales, "Right to left", and Mark All Reviewed when
/// the locale has machine-translated fields.
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
                ForEach(viewModel.editorLocales) { locale in
                    Text(locale.name).tag(Optional(locale))
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
}
