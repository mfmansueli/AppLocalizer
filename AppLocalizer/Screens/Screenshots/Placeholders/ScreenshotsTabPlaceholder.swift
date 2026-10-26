//
//  ScreenshotsTabPlaceholder.swift
//  AppLocalizer
//

import SwiftUI

/// Template, Captions and Captures until their editors arrive: what the
/// view will do, and a way back to Sets.
struct ScreenshotsTabPlaceholder: View {
    let tab: ScreenshotsTab
    var onShowSets: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(tab.title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            Button("Show Sets", action: onShowSets)
                .accessibilityIdentifier("screenshots.placeholder.showSets")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("screenshots.placeholder.\(tab.rawValue)")
    }

    private var symbol: String {
        switch tab {
        case .sets: "square.grid.3x3"
        case .template: "rectangle.on.rectangle"
        case .captions: "text.quote"
        case .captures: "iphone"
        }
    }

    private var message: String {
        switch tab {
        case .sets: ""
        case .template: String(localized: "The template editor isn’t available in this build yet. Sets already renders with the saved template.")
        case .captions: String(localized: "The captions editor isn’t available in this build yet. Sets already renders the saved captions.")
        case .captures: String(localized: "The captures view isn’t available in this build yet. Sets already uses the imported captures.")
        }
    }
}
