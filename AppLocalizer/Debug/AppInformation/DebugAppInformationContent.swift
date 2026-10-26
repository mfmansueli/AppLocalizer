//
//  DebugAppInformationContent.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen Journal's App Information as the design draws it: Lifestyle and
/// Health & Fitness, no third-party content, version 1.4 being prepared
/// (1.3 is live), an age rating questionnaire whose 2025 questions aren't
/// answered yet, Ana Ribeiro as App Review's contact, and build 42 using
/// exempt encryption only. Accessibility comes in the design's states
/// (`AccessibilitySample`). Other sample apps get their released version.
enum DebugAppInformationContent {
    static let editableVersionID = "lumen-v14"
    static let liveVersionID = "lumen-v13"
    static let appInfoID = "lumen-info-next"
    static let ageRatingDeclarationID = "lumen-age"
    static let reviewDetailID = "lumen-review-14"
    static let buildID = "lumen-build-42"

    static let versions = [
        StorePageVersion(id: editableVersionID, listingVersion: ListingVersion("1.4", state: .prepareForSubmission), platform: "IOS"),
        StorePageVersion(id: liveVersionID, listingVersion: ListingVersion("1.3", state: .readyForDistribution), platform: "IOS"),
    ]

    static let general = GeneralValues(
        primaryCategory: "LIFESTYLE",
        secondaryCategory: "HEALTH_AND_FITNESS",
        contentRights: .doesNotUseThirdPartyContent,
        copyright: "© 2026 Northpier Studio",
        release: .afterApproval,
        earliestReleaseDate: try? Date("2026-11-10T09:00:00Z", strategy: .iso8601)
    )

    static let review = AppReviewValues(
        firstName: "Ana",
        lastName: "Ribeiro",
        phone: "+39 011 555 0142",
        email: "review@northpier.dev",
        notes: """
        Lumen has no account or sign-in. Lumen Plus can be bought with a sandbox account from the paywall in Settings → Lumen Plus. \
        Weekly reflections appear once a week has three or more entries.
        """
    )

    /// The questions App Store Connect has answers for: everything but the
    /// ones Claude Code answers in `info-age`.
    static var ageRating: AgeRatingValues {
        let unanswered: Set<AgeRatingQuestion> = [
            .wellness, .userGeneratedContent, .messaging, .webAccess, .advertising, .parentalControls, .ageAssurance,
        ]
        var values: [String: AppInformationAPIValue] = [AppInformationChangeBuilder.overrideAttribute: .string("NONE")]
        for question in AgeRatingQuestion.allCases where !unanswered.contains(question) {
            values[question.apiKey] = question.defaultAnswer.apiValue
        }
        return AgeRatingValues(answers: AgeRatingAnswers(attributes: values), override: nil, currentRating: "4+", apiValues: values)
    }

    static func lumen(versionID: String?) -> AppInformationContent {
        let version = versions.first { $0.id == versionID } ?? versions[0]
        let isEditable = version.isEditable
        return AppInformationContent(
            versions: versions,
            version: version,
            ids: AppInformationResourceIDs(
                appID: DebugFixtures.AppID.lumen,
                appInfoID: appInfoID,
                ageRatingDeclarationID: ageRatingDeclarationID,
                versionID: version.id,
                reviewDetailID: isEditable ? reviewDetailID : "lumen-review-13"
            ),
            general: general,
            ageRating: ageRating,
            review: review,
            export: ExportComplianceValues(
                buildID: isEditable ? buildID : "lumen-build-37",
                buildNumber: isEditable ? "42" : "37",
                usesNonExemptEncryption: false
            )
        )
    }

    /// Any other sample app: one live version, answered and complete.
    static func released(_ app: StoreApp, versionString: String) -> AppInformationContent {
        let version = StorePageVersion(id: "\(app.id)-live", listingVersion: ListingVersion(versionString, state: .readyForDistribution), platform: "IOS")
        var ageRating = ageRating
        for question in AgeRatingQuestion.allCases {
            ageRating.apiValues[question.apiKey] = question.defaultAnswer.apiValue
        }
        return AppInformationContent(
            versions: [version],
            version: version,
            ids: AppInformationResourceIDs(appID: app.id, appInfoID: "\(app.id)-info", ageRatingDeclarationID: "\(app.id)-age", versionID: version.id),
            general: GeneralValues(primaryCategory: "PRODUCTIVITY", contentRights: .doesNotUseThirdPartyContent, copyright: "© 2026 Northpier Studio"),
            ageRating: ageRating,
            review: review,
            export: ExportComplianceValues(buildID: "\(app.id)-build", buildNumber: "12", usesNonExemptEncryption: false)
        )
    }
}
#endif
