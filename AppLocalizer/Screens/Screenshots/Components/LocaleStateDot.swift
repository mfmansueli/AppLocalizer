//
//  LocaleStateDot.swift
//  AppLocalizer
//

import SwiftUI

/// The dot after a locale in the viewer's list: red when its render fails
/// a check, blue when it's waiting for Review & Push, grey otherwise.
struct LocaleStateDot: View {
    let state: ScreenshotCellState?

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }

    private var color: Color {
        switch state {
        case .failed: Palette.dangerMark
        case .notPushed: Palette.unsaved
        default: Palette.fill3
        }
    }
}
