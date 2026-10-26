//
//  NoCapturesView.swift
//  AppLocalizer
//

import SwiftUI

/// Sets before any capture: what a capture is, and the two ways to get
/// some.
struct NoCapturesView: View {
    let appName: String
    var onImport: () -> Void
    var onUseLive: () -> Void

    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "iphone")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Palette.label3)
                .accessibilityHidden(true)
            Text("No captures yet")
                .font(.title3.weight(.semibold))
            Text("A capture is a real screenshot of \(appName), ideally taken in each language. AppLocalizer puts it in a template with a caption; it never draws your interface.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
            HStack(spacing: Spacing.small) {
                Button("Import Captures…", action: onImport)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("screenshots.importCaptures")
                Button("Use Live Screenshots", action: onUseLive)
                    .accessibilityIdentifier("screenshots.useLive")
            }
            .padding(.top, Spacing.xxSmall)
            Text("Folders, fastlane snapshot output and Xcode test results all work.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .padding(.top, Spacing.xxSmall)
        }
        .padding(Spacing.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.noCaptures")
    }
}
