//
//  TemplateStage.swift
//  AppLocalizer
//

import SwiftUI

/// The neutral stage: the canvas, with the stress strip beside it, or
/// under it for a landscape canvas.
struct TemplateStage: View {
    let model: TemplateEditorViewModel

    var body: some View {
        ScrollView(.vertical) {
            Group {
                if model.orientation == .landscape {
                    VStack(alignment: .leading, spacing: Spacing.xxLarge) {
                        canvas
                        StressStripView(model: model, cardWidth: 190)
                    }
                } else {
                    HStack(alignment: .top, spacing: 28) {
                        canvas
                        StressStripView(model: model, cardWidth: min(140, model.displayType.thumbnailWidth(phone: 112, tablet: 140)))
                    }
                }
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.stage)
    }

    private var canvas: some View {
        TemplateCanvasView(model: model, width: canvasWidth)
    }

    /// 250 pt for an iPhone portrait canvas, 470 for iPad landscape, 360
    /// for iPhone Duo's inner display in portrait.
    private var canvasWidth: CGFloat {
        switch (model.displayType, model.orientation) {
        case (.iPad, .portrait): 330
        case (.iPad, .landscape): 470
        case (.iPhoneDuo, .portrait): 360
        case (.iPhoneDuo, .landscape): 500
        case (_, .portrait): 250
        case (_, .landscape): 520
        }
    }
}
