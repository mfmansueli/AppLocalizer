//
//  CaptionsView.swift
//  AppLocalizer
//

import SwiftUI

/// The Captions tab: the toolbar, the translation banner while a batch
/// runs, the locales × slots table, and the editor for the selected
/// caption.
struct CaptionsView: View {
    let viewModel: ScreenshotsViewModel
    @Environment(TranslationPreferences.self) private var preferences

    private var model: CaptionsViewModel { viewModel.captions }

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            CaptionsToolbar(model: model) {
                model.translation.prepare(provider: preferences.provider, glossary: preferences.glossary)
                model.isTranslateSheetPresented = true
            }
            if model.translation.isRunning {
                CaptionTranslationBanner(translation: model.translation)
            }
            Divider()
            HStack(spacing: 0) {
                CaptionsTable(viewModel: viewModel, model: model)
                if model.selection != nil {
                    Divider()
                    CaptionEditorPanel(model: model)
                        .frame(width: 320)
                }
            }
        }
        .sheet(isPresented: $model.isTranslateSheetPresented) {
            TranslateCaptionsSheet(viewModel: viewModel, translation: model.translation)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.captions")
    }
}
