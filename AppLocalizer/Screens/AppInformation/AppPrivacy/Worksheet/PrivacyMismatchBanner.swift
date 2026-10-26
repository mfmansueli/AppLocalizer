//
//  PrivacyMismatchBanner.swift
//  AppLocalizer
//

import SwiftUI

/// The cross-check: an SDK's privacy manifest declares a type the
/// worksheet says isn't collected. Mark it collected, or say why not.
struct PrivacyMismatchBanner: View {
    let mismatch: PrivacyManifestMismatch
    let viewModel: AppPrivacyViewModel

    var body: some View {
        PrivacyNotice(isWarning: true) {
            Text(mismatch.message)
                .fixedSize(horizontal: false, vertical: true)
        } actions: {
            Button(String(localized: "Mark as Collected")) {
                viewModel.markCollected(mismatch.type)
            }
            .accessibilityIdentifier("appInformation.appPrivacy.mismatch.\(mismatch.type.rawValue).collected")
            Button(String(localized: "Not Collected, Explain…")) {
                viewModel.explainingType = mismatch.type
            }
            .accessibilityIdentifier("appInformation.appPrivacy.mismatch.\(mismatch.type.rawValue).explain")
        }
        .accessibilityIdentifier("appInformation.appPrivacy.mismatch.\(mismatch.type.rawValue)")
    }
}
