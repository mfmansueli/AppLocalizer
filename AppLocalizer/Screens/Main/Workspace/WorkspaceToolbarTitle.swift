//
//  WorkspaceToolbarTitle.swift
//  AppLocalizer
//

import SwiftUI

/// The app's name over its bundle ID, at the toolbar's leading edge. The
/// window's own title can't shrink, so in a narrow toolbar Review & Push
/// went into the overflow menu; this one truncates first ("Lume…"), as the
/// design draws it.
struct WorkspaceToolbarTitle: View {
    let name: String
    let bundleID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .font(.headline)
            Text(bundleID)
                .font(.subheadline)
                .foregroundStyle(Palette.label2)
        }
        .lineLimit(1)
        .frame(minWidth: 44, maxWidth: 240, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workspace.title")
    }
}

#Preview {
    WorkspaceToolbarTitle(name: "Lumen Journal", bundleID: "dev.northpier.lumen")
        .frame(width: 60)
        .padding()
}
