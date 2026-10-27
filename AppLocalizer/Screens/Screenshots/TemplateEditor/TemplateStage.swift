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
                        StressStripView(model: model, cardWidth: model.displayType.isTablet ? 140 : 112)
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

    /// 250 pt for an iPhone portrait canvas, 470 for iPad landscape.
    private var canvasWidth: CGFloat {
        switch (model.displayType.isTablet, model.orientation) {
        case (false, .portrait): 250
        case (false, .landscape): 520
        case (true, .portrait): 330
        case (true, .landscape): 470
        }
    }
}
