//
//  PrivacyRowStatusPill.swift
//  AppLocalizer
//

import SwiftUI

/// Unreviewed (purple, as everywhere else in the app), Accepted, Edited by
/// you, Yours, or Suggestion rejected (outlined).
struct PrivacyRowStatusPill: View {
    let status: PrivacyRowStatus

    var body: some View {
        Pill(text: status.title, style: style)
            // One element: a pill is a stack of views, which would leave
            // the label on none of them.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Status: \(status.title)"))
    }

    private var style: PillStyle {
        switch status {
        case .unreviewed: .machineTranslated
        case .rejected: .outline
        case .accepted, .edited, .yours: .neutral
        }
    }
}
