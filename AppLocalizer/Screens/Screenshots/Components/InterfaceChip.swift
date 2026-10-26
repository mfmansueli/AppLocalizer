//
//  InterfaceChip.swift
//  AppLocalizer
//

import SwiftUI

/// "UI" on a thumbnail whose capture shows the primary locale's interface.
struct InterfaceChip: View {
    var body: some View {
        Text("UI")
            .font(.system(size: 8, weight: .bold).monospaced())
            .foregroundStyle(Color.black.opacity(0.85))
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(Palette.warningMark, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            .accessibilityHidden(true)
    }
}
