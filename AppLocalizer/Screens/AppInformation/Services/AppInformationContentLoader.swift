//
//  AppInformationContentLoader.swift
//  AppLocalizer
//

import Foundation

/// Reads one app's App Information from App Store Connect: its versions,
/// the app info being prepared (else the live one) with categories and the
/// age rating questionnaire, content rights, and for the chosen version its
/// copyright, release, review details and build.
struct AppInformationContentLoader: Sendable {
    let client: AppStoreConnectClient

    func content(for app: StoreApp, versionID: String?) async throws -> AppInformationContent {
        let versionResources = try await client.appStoreVersionReleases(appID: app.id)
        let platforms = versionResources.map(\.attributes.platform)
        let versions = StorePageVersion.pickerVersions(from: versionResources.compactMap {
            Self.version($0, isFirstVersion: StorePageVersion.isOnlyVersion(of: $0.attributes.platform, among: platforms))
        })
        let version = versions.first { $0.id == versionID } ?? StorePageVersion.preferred(in: versions)
        let release = versionResources.first { $0.id == version?.id }?.attributes

        let appInfos = try await client.appInfos(appID: app.id)
        guard let appInfoID = StorePageContentLoader.preferredAppInfo(in: appInfos)?.id else {
            throw AppStoreConnectError.notFound(detail: String(localized: "This app has no app information yet."))
        }
        let appInfo = try await client.appInfoDetail(appInfoID: appInfoID)
        let appResource = try await client.appInformationApp(appID: app.id)
        let declaration = try await client.ageRatingDeclaration(appInfoID: appInfoID)

        var ids = AppInformationResourceIDs(appID: app.id, appInfoID: appInfoID, ageRatingDeclarationID: declaration?.id, versionID: version?.id)
        var review = AppReviewValues()
        var export = ExportComplianceValues()
        if let versionID = version?.id {
            let detail = try await client.appStoreReviewDetail(versionID: versionID)
            ids.reviewDetailID = detail?.id
            review = detail.map { Self.review($0.attributes) } ?? AppReviewValues()
            let build = try await client.versionBuild(versionID: versionID)
            export = ExportComplianceValues(
                buildID: build?.id,
                buildNumber: build?.attributes.version,
                usesNonExemptEncryption: build?.attributes.usesNonExemptEncryption
            )
        }
        export.declaredAnswers = try await Self.declaredAnswers(encryptionDeclarations(appID: app.id))

        return AppInformationContent(
            versions: versions,
            version: version,
            ids: ids,
            general: Self.general(appInfo: appInfo, app: appResource?.attributes, release: release),
            ageRating: Self.ageRating(declaration?.attributes, currentRating: appInfo?.attributes.appStoreAgeRating),
            review: review,
            export: export
        )
    }

    /// Declared answers only fill in Export Compliance, so a list App Store
    /// Connect can't find leaves them out instead of failing every page.
    private func encryptionDeclarations(appID: String) async throws -> [AppStoreConnectResource<AppEncryptionDeclarationAttributes>] {
        do {
            return try await client.appEncryptionDeclarations(appID: appID)
        } catch AppStoreConnectError.notFound {
            return []
        }
    }

    // MARK: - Mapping

    /// A version the picker knows. `READY_FOR_SALE` (the older state) is live.
    static func version(_ resource: AppStoreConnectResource<AppStoreVersionReleaseAttributes>, isFirstVersion: Bool) -> StorePageVersion? {
        guard let state = state(of: resource.attributes) else { return nil }
        return StorePageVersion(
            id: resource.id,
            listingVersion: ListingVersion(resource.attributes.versionString, state: state, isFirstVersion: isFirstVersion),
            platform: resource.attributes.platform,
            createdDate: resource.attributes.createdDate.flatMap { try? Date($0, strategy: .iso8601) }
        )
    }

    static func state(of attributes: AppStoreVersionReleaseAttributes) -> ListingVersionState? {
        if let state = attributes.state.flatMap(ListingVersionState.init(rawValue:)) { return state }
        return attributes.appStoreState == "READY_FOR_SALE" ? .readyForDistribution : nil
    }

    static func general(
        appInfo: AppInformationResourceDocument<AppInfoRatingAttributes>.Resource?,
        app: AppInformationAppAttributes?,
        release: AppStoreVersionReleaseAttributes?
    ) -> GeneralValues {
        let rights = app?.contentRightsDeclaration.flatMap(ContentRights.init(rawValue:))
        return GeneralValues(
            primaryCategory: appInfo?.relationshipID("primaryCategory"),
            secondaryCategory: appInfo?.relationshipID("secondaryCategory"),
            gamesSubcategories: AppInformationChangeBuilder.subcategoryRelationships.compactMap { appInfo?.relationshipID($0) },
            contentRights: rights,
            rightsConfirmed: rights == .usesThirdPartyContent,
            copyright: release?.copyright ?? "",
            release: release?.releaseType.flatMap(ReleaseOption.init(rawValue:)),
            earliestReleaseDate: release?.earliestReleaseDate.flatMap(AppInformationChangeBuilder.date)
        )
    }

    static func ageRating(_ attributes: AgeRatingDeclarationAttributes?, currentRating: String?) -> AgeRatingValues {
        let values = attributes?.values ?? [:]
        let override = attributes?.ageRatingOverride.flatMap { AgeRating(apiValue: $0) }
        return AgeRatingValues(
            answers: AgeRatingAnswers(attributes: values),
            override: override,
            currentRating: AgeRating.title(forAPIValue: currentRating),
            apiValues: values
        )
    }

    static func review(_ attributes: AppStoreReviewDetailAttributes) -> AppReviewValues {
        AppReviewValues(
            firstName: attributes.contactFirstName ?? "",
            lastName: attributes.contactLastName ?? "",
            phone: attributes.contactPhone ?? "",
            email: attributes.contactEmail ?? "",
            signInRequired: attributes.demoAccountRequired ?? false,
            userName: attributes.demoAccountName ?? "",
            password: attributes.demoAccountPassword ?? "",
            notes: attributes.notes ?? ""
        )
    }

    /// The newest declaration's answers, when there's one.
    static func declaredAnswers(_ declarations: [AppStoreConnectResource<AppEncryptionDeclarationAttributes>]) -> ExportComplianceAnswers? {
        let newest = declarations.max { ($0.attributes.createdDate ?? "") < ($1.attributes.createdDate ?? "") }
        guard let attributes = newest?.attributes else { return nil }
        let pairs: [(ExportComplianceQuestion, Bool?)] = [
            (.usesEncryption, attributes.usesEncryption),
            (.isExempt, attributes.exempt),
            (.proprietary, attributes.containsProprietaryCryptography),
            (.thirdParty, attributes.containsThirdPartyCryptography),
            (.availableInFrance, attributes.availableOnFrenchStore),
        ]
        return ExportComplianceAnswers(answers: Dictionary(uniqueKeysWithValues: pairs.compactMap { question, value in value.map { (question, $0) } }))
    }
}
