//
//  AppInformationCannedResponses.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// App Store Connect's JSON for App Information's reads, in the order the
/// live loaders ask for it.
enum AppInformationCannedResponses {
    static func page(_ resources: [String]) -> CannedHTTPResponse {
        CannedHTTPResponse(body: #"{"data":[\#(resources.joined(separator: ","))]}"#)
    }

    static func single(_ resource: String) -> CannedHTTPResponse {
        CannedHTTPResponse(body: #"{"data":\#(resource)}"#)
    }

    static let notFound = CannedHTTPResponse(
        statusCode: 404,
        body: #"{"errors":[{"status":"404","code":"NOT_FOUND","title":"Not found","detail":"There is no resource."}]}"#
    )

    static func version(_ id: String, _ versionString: String, state: String, platform: String = "IOS", created: String = "2026-10-01T10:00:00Z") -> String {
        #"""
        {"type":"appStoreVersions","id":"\#(id)","attributes":{"versionString":"\#(versionString)","platform":"\#(platform)",\#
        "appVersionState":"\#(state)","createdDate":"\#(created)","copyright":"© 2026 Northpier Studio","releaseType":"AFTER_APPROVAL"}}
        """#
    }

    static let versions = page([
        version("v14", "1.4", state: "PREPARE_FOR_SUBMISSION", created: "2026-10-01T10:00:00Z"),
        version("v13", "1.3", state: "READY_FOR_DISTRIBUTION", created: "2026-08-01T10:00:00Z"),
    ])

    /// Lumen's versions with its first visionOS version, not live yet.
    static let versionsWithVision = page([
        version("v14", "1.4", state: "PREPARE_FOR_SUBMISSION", created: "2026-10-01T10:00:00Z"),
        version("v13", "1.3", state: "READY_FOR_DISTRIBUTION", created: "2026-08-01T10:00:00Z"),
        version("vv14", "1.4", state: "PREPARE_FOR_SUBMISSION", platform: "VISION_OS", created: "2026-10-02T10:00:00Z"),
    ])

    static let appInfos = page([
        #"{"type":"appInfos","id":"info-live","attributes":{"state":"READY_FOR_DISTRIBUTION"}}"#,
        #"{"type":"appInfos","id":"info-next","attributes":{"state":"PREPARE_FOR_SUBMISSION"}}"#,
    ])

    static let appInfoDetail = single(#"""
    {"type":"appInfos","id":"info-next","attributes":{"appStoreAgeRating":"NINE_PLUS","state":"PREPARE_FOR_SUBMISSION"},\#
    "relationships":{"primaryCategory":{"data":{"type":"appCategories","id":"LIFESTYLE"}},\#
    "secondaryCategory":{"data":null},"primarySubcategoryOne":{"data":null}}}
    """#)

    static let app = single(#"""
    {"type":"apps","id":"6450000001","attributes":{"contentRightsDeclaration":"DOES_NOT_USE_THIRD_PARTY_CONTENT",\#
    "accessibilityUrl":"https://lumen.example/accessibility"}}
    """#)

    static let ageRating = single(#"""
    {"type":"ageRatingDeclarations","id":"age-1","attributes":{"violenceCartoonOrFantasy":"NONE","healthOrWellnessTopics":true,\#
    "socialMedia":false,"messagingAndChat":null,"ageRatingOverrideV2":"NONE"}}
    """#)

    static let reviewDetail = single(#"""
    {"type":"appStoreReviewDetails","id":"review-1","attributes":{"contactFirstName":"Ana","contactLastName":"Ribeiro",\#
    "contactPhone":"+39 011 555 0142","contactEmail":"review@northpier.dev","demoAccountRequired":false,"notes":"No sign-in."}}
    """#)

    static let build = single(#"{"type":"builds","id":"b42","attributes":{"version":"42","usesNonExemptEncryption":false}}"#)

    static let encryptionDeclarations = page([
        #"""
        {"type":"appEncryptionDeclarations","id":"e1","attributes":{"usesEncryption":true,"exempt":true,\#
        "containsProprietaryCryptography":false,"containsThirdPartyCryptography":false,"availableOnFrenchStore":true,\#
        "createdDate":"2026-09-01T10:00:00Z"}}
        """#,
    ])

    /// Every read of `content(for:versionID:)`, in order.
    static let content: [CannedHTTPResponse] = [
        versions, appInfos, appInfoDetail, app, ageRating, reviewDetail, build, encryptionDeclarations,
    ]

    static func declaration(_ id: String, family: String, state: String, supports: [String]) -> String {
        let flags = AccessibilityFeature.allCases.map { #""\#($0.apiKey)":\#(supports.contains($0.apiKey))"# }.joined(separator: ",")
        return #"{"type":"accessibilityDeclarations","id":"\#(id)","attributes":{"deviceFamily":"\#(family)","state":"\#(state)",\#(flags)}}"#
    }

    /// Every read of `accessibility(for:)`, in order.
    static let accessibility: [CannedHTTPResponse] = [
        page([
            declaration("d1", family: "IPHONE", state: "PUBLISHED", supports: ["supportsVoiceover", "supportsLargerText"]),
            declaration("d0", family: "IPHONE", state: "REPLACED", supports: ["supportsVoiceover"]),
            declaration("d2", family: "IPAD", state: "DRAFT", supports: ["supportsVoiceover"]),
            declaration("d3", family: "APPLE_WATCH", state: "DRAFT", supports: []),
        ]),
        versionsWithVision,
        app,
    ]
}
