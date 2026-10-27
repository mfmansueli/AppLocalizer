//
//  PrivacyFastlaneImport.swift
//  AppLocalizer
//

import Foundation

/// What a fastlane `app_privacy_details.json` says, ready to preview before
/// it replaces the worksheet's answers.
struct PrivacyFastlaneImport: Hashable, Sendable {
    var collects: Bool
    var answers: [PrivacyDataType: PrivacyAnswer]
    /// Categories the file names that aren't one of the 35, as written.
    var unknownCategories: [String] = []

    /// The imported types in App Store Connect's order.
    var types: [PrivacyDataType] {
        PrivacyDataType.allCases.filter { answers[$0] != nil }
    }
}
