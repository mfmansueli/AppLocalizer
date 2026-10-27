//
//  TemplateEditorBanners.swift
//  AppLocalizer
//

import SwiftUI

/// What the editor needs to say: a refused edit, a font that couldn't be
/// uploaded, or that the primary locale has no captions yet.
struct TemplateEditorBanners: View {
    let viewModel: ScreenshotsViewModel
    @Bindable var model: TemplateEditorViewModel

    var body: some View {
        if let refusals = model.refusals {
            Banner(
                kind: .warning,
                title: String(localized: "The template can’t take that."),
                message: refusals.items.map(\.reason).joined(separator: " "),
                isInline: true
            ) {
                dismiss { model.refusals = nil }
            }
            .accessibilityIdentifier("screenshots.template.refusal")
        }
        if let error = model.uploadError {
            Banner(kind: .warning, title: String(localized: "Couldn’t use that font."), message: error, isInline: true) {
                dismiss { model.uploadError = nil }
            }
            .accessibilityIdentifier("screenshots.template.uploadError")
        }
        if model.needsPrimaryCaptions {
            Banner(
                kind: .info,
                title: String(localized: "Write your captions next."),
                message: String(localized: "The renders below have empty caption boxes until \(viewModel.context.primaryLocale.name) has captions."),
                isInline: true
            ) {
                Button("Go to Captions") {
                    viewModel.editCaption(at: LocaleSlot(locale: viewModel.context.primaryLocale.code, slot: 0))
                }
            }
            .accessibilityIdentifier("screenshots.template.writeCaptions")
        }
    }

    private func dismiss(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Dismiss"))
    }
}
