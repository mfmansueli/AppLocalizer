//
//  WorkspaceToolbarTitle.swift
//  AppLocalizer
//

import SwiftUI

/// The app's name over its bundle ID, at the toolbar's leading edge. When
/// `WorkspaceToolbarLayout` says space is short it gets a compact width and
/// truncates ("Lume…") before Review & Push would go into the overflow menu.
struct WorkspaceToolbarTitle: View {
    let name: String
    let bundleID: String
    /// A fixed width, or nil for the name's own width.
    var width: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .font(.headline)
            Text(bundleID)
                .font(.subheadline)
                .foregroundStyle(Palette.label2)
        }
        .lineLimit(1)
        .frame(width: width, alignment: .leading)
        .frame(maxWidth: WorkspaceToolbarLayout.maxTitleWidth, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workspace.title")
    }
}

#Preview {
    WorkspaceToolbarTitle(name: "Lumen Journal", bundleID: "dev.northpier.lumen", width: 60)
        .padding()
}
