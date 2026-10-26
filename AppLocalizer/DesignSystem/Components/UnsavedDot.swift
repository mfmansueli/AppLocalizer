//
//  UnsavedDot.swift
//  AppLocalizer
//

import SwiftUI

/// The 8 pt accent dot on anything with changes that aren't pushed yet.
struct UnsavedDot: View {
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(Palette.unsaved)
            .frame(width: size, height: size)
            .accessibilityElement()
            .accessibilityLabel(Text("Not pushed"))
    }
}

#Preview {
    UnsavedDot()
        .padding()
}
