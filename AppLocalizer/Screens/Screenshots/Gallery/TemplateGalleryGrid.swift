//
//  TemplateGalleryGrid.swift
//  AppLocalizer
//

import SwiftUI

/// The gallery's cards for the chosen style, three to a row where there's
/// room, shared by the first-run picker and the Templates sheet.
struct TemplateGalleryGrid: View {
    let viewModel: ScreenshotsViewModel
    /// "Use This Template" on first run; the sheet says "Switch to This"
    /// or, for the template in use, "Start Over from This".
    let isFirstRun: Bool
    var onUse: (TemplateStarter) -> Void

    private let columns = [GridItem(.adaptive(minimum: 268), spacing: 14, alignment: .top)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            ForEach(TemplateStarter.starters(in: viewModel.galleryStyle)) { starter in
                let isInUse = !isFirstRun && viewModel.document?.template?.starter == starter
                TemplateGalleryCard(
                    starter: starter,
                    images: viewModel.starterImages(starter),
                    fontNote: viewModel.starterFontNote(starter),
                    isInUse: isInUse,
                    buttonTitle: isFirstRun ? String(localized: "Use This Template") : viewModel.templateEditor.starterButtonTitle(starter),
                    isProminent: !isInUse
                ) {
                    onUse(starter)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.gallery")
    }
}
