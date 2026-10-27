//
//  RenderCheckRow.swift
//  AppLocalizer
//

import SwiftUI

/// One check in the viewer's list: passed, failed, a warning or waiting.
struct RenderCheckRow: View {
    let check: RenderCheck

    var body: some View {
        Label {
            Text(check.text)
                .foregroundStyle(check.status == .failed ? Palette.danger : Palette.label)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(tint)
        }
        .font(.callout)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(statusTitle): \(check.text)"))
    }

    private var symbol: String {
        switch check.status {
        case .passed: "checkmark"
        case .failed: "exclamationmark.circle"
        case .warning: "exclamationmark.triangle"
        case .pending: "circle.dashed"
        }
    }

    private var tint: Color {
        switch check.status {
        case .passed: Palette.label2
        case .failed: Palette.dangerMark
        case .warning: Palette.warningMark
        case .pending: Palette.label3
        }
    }

    private var statusTitle: String {
        switch check.status {
        case .passed: String(localized: "Passed")
        case .failed: String(localized: "Failed")
        case .warning: String(localized: "Warning")
        case .pending: String(localized: "Waiting")
        }
    }
}
