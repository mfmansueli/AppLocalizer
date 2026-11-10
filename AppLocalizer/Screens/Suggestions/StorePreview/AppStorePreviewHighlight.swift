//
//  AppStorePreviewHighlight.swift
//  AppLocalizer
//

import SwiftUI

/// Marks a suggestion nobody has accepted yet on the preview: a purple tint
/// and underline, the same purple as its badge.
struct AppStorePreviewHighlight: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        content
            .background(alignment: .bottom) {
                if isOn {
                    Palette.machineTranslatedMark.frame(height: 1.5)
                }
            }
            .background {
                if isOn {
                    RoundedRectangle(cornerRadius: 3, style: .continuous).fill(Palette.machineTranslatedTint)
                }
            }
    }
}
