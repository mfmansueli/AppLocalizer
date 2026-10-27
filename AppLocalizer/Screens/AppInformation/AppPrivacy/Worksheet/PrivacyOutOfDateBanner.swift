//
//  PrivacyOutOfDateBanner.swift
//  AppLocalizer
//

import SwiftUI

/// After Mark as Published, a scan or an edit changed the answers: App
/// Store Connect may no longer match.
struct PrivacyOutOfDateBanner: View {
    let date: Date
    let onOpenChecklist: () -> Void

    var body: some View {
        PrivacyNotice(isWarning: true) {
            Text("**Out of date with App Store Connect.** You marked these answers as published on \(date.formatted(date: .abbreviated, time: .omitted)). A later scan or an edit changed them, so App Store Connect may no longer match. Review the changes, then update App Store Connect with the checklist.")
                .fixedSize(horizontal: false, vertical: true)
        } actions: {
            Button(String(localized: "Open Checklist"), action: onOpenChecklist)
                .accessibilityIdentifier("appInformation.appPrivacy.openChecklist")
        }
        .accessibilityIdentifier("appInformation.appPrivacy.outOfDate")
    }
}
