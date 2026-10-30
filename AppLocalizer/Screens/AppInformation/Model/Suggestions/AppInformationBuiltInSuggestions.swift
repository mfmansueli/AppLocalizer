//
//  AppInformationBuiltInSuggestions.swift
//  AppLocalizer
//

import Foundation

/// App Information's built-in checks, on the values as shown (App Store
/// Connect's with pending changes on top), for an editable version only:
/// - A copyright that still names an earlier year: this year instead.
/// - Contact details App Review needs that are empty, while the previous
///   version had them: that version's.
/// - Age Rating's Advertising, unanswered, when App Privacy's last scan
///   found no ad SDK and nothing is collected for ads: No.
enum AppInformationBuiltInSuggestions {
    /// The previous version's App Review details, and its version string.
    struct PreviousReview: Hashable, Sendable {
        var versionString: String
        var review: AppReviewValues
    }

    static func suggestions(
        general: GeneralValues?,
        review: AppReviewValues?,
        version: StorePageVersion?,
        previous: PreviousReview?,
        appID: StoreApp.ID,
        now: Date = .now
    ) -> [FieldSuggestion] {
        guard let version, version.isEditable else { return [] }
        var found: [FieldSuggestion] = []
        if let general, let copyright = copyright(general.copyright, version: version.versionString, appID: appID, now: now) {
            found.append(copyright)
        }
        if let review, let previous {
            found += contact(review, previous: previous, appID: appID)
        }
        return found
    }

    /// "© 2025 Northpier Studio" → "© 2026 Northpier Studio". The last year
    /// named is the one that moves, so "2019–2025" becomes "2019–2026".
    static func copyright(_ text: String, version: String, appID: StoreApp.ID, now: Date) -> FieldSuggestion? {
        let year = Calendar(identifier: .gregorian).component(.year, from: now)
        guard let match = text.matches(of: /(19|20)\d{2}/).last, let stated = Int(text[match.range]), stated < year else { return nil }
        var updated = text
        updated.replaceSubrange(match.range, with: String(year))
        let reason = String(localized: "Still says \(String(stated)), and \(version) will ship in \(String(year)).")
        return .builtIn(appID: appID, target: .appInformation(.copyright), value: updated, reason: reason)
    }

    /// No for Advertising, from App Privacy's last scan: nothing it found
    /// is an ad network, and no data type is used for advertising.
    static func advertising(current: String, worksheet: PrivacyWorksheet, appID: StoreApp.ID) -> FieldSuggestion? {
        guard current.isEmpty, let scan = worksheet.lastScan else { return nil }
        let adPurposes: Set<PrivacyPurpose> = [.thirdPartyAdvertising, .developersAdvertising]
        let collectsForAds = worksheet.entries.values.contains { !$0.answer.purposes.isDisjoint(with: adPurposes) }
        let hasAdSDK = scan.sdks.contains { sdk in adSDKNames.contains { sdk.name.localizedCaseInsensitiveContains($0) } }
        guard !collectsForAds, !hasAdSDK else { return nil }
        return .builtIn(
            appID: appID,
            target: AppInformationSuggestionSlot.ageRating(.advertising).target,
            value: AgeRatingAnswer.negative.rawValue,
            reason: String(localized: "App Privacy’s last scan found no advertising SDKs, and no data type is used for ads.")
        )
    }

    /// Ad networks a scan may list, by a part of their name.
    static let adSDKNames = [
        "AdMob", "GoogleMobileAds", "AppLovin", "ironSource", "UnityAds", "Unity Ads", "AudienceNetwork", "Vungle", "Liftoff",
        "InMobi", "Chartboost", "Mintegral", "Pangle", "AdColony", "Digital Turbine", "Fyber", "Smaato", "Amazon Publisher",
    ]

    private static func contact(_ review: AppReviewValues, previous: PreviousReview, appID: StoreApp.ID) -> [FieldSuggestion] {
        let fields: [AppInformationSuggestionField] = [.contactFirstName, .contactLastName, .contactPhone, .contactEmail]
        return fields.compactMap { field in
            guard let reviewField = field.reviewField else { return nil }
            let current = review.text(reviewField).trimmingCharacters(in: .whitespaces)
            let earlier = previous.review.text(reviewField).trimmingCharacters(in: .whitespaces)
            guard current.isEmpty, !earlier.isEmpty else { return nil }
            let reason = field == .contactPhone
                ? String(localized: "The phone number from \(previous.versionString)’s App Review details.")
                : String(localized: "From \(previous.versionString)’s App Review details.")
            return .builtIn(appID: appID, target: .appInformation(field), value: earlier, reason: reason)
        }
    }
}
