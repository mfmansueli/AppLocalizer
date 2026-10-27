//
//  DeltaPill.swift
//  AppLocalizer
//

import SwiftUI

/// A price change as a signed whole percent: teal ▼ for decreases, orange ▲
/// for increases, never red and green (a lower price isn't an error). The
/// arrow and sign keep it readable without color.
struct DeltaPill: View {
    /// Signed whole percent, e.g. -50.
    let percent: Int

    var body: some View {
        Pill(text: text, style: style)
            .accessibilityElement()
            .accessibilityLabel(accessibilityText)
    }

    private var text: String {
        switch percent {
        case ..<0: "▼ −\(-percent)%"
        case 1...: "▲ +\(percent)%"
        default: "0%"
        }
    }

    private var style: PillStyle {
        switch percent {
        case ..<0: .decrease
        case 1...: .increase
        default: .neutral
        }
    }

    private var accessibilityText: String {
        switch percent {
        case ..<0: String(localized: "Decrease, \(-percent) percent")
        case 1...: String(localized: "Increase, \(percent) percent")
        default: String(localized: "No change")
        }
    }
}

#Preview {
    HStack {
        DeltaPill(percent: -50)
        DeltaPill(percent: 12)
        DeltaPill(percent: 0)
    }
    .padding()
}
