//
//  AppStoreConnectClient+AppInformation.swift
//  AppLocalizer
//

import Foundation

// App Information's reads: the app's content rights and accessibility URL,
// versions with copyright and release, the app info's categories and age
// rating, a version's review details and build, and encryption
// declarations. Writes are `PushRequest`s queued as pending changes.
extension AppStoreConnectClient {
    private static let pageLimit = URLQueryItem(name: "limit", value: "200")

    /// `GET /v1/apps/{id}` with content rights and the accessibility URL.
    func appInformationApp(appID: String) async throws -> AppStoreConnectResource<AppInformationAppAttributes>? {
        let query = [URLQueryItem(name: "fields[apps]", value: "contentRightsDeclaration,accessibilityUrl")]
        let document: AppInformationResourceDocument<AppInformationAppAttributes> = try await get(url("/v1/apps/\(appID)", query: query))
        return document.data.map { AppStoreConnectResource(type: $0.type, id: $0.id, attributes: $0.attributes) }
    }

    /// Every App Store version with its copyright and release
    /// (`GET /v1/apps/{id}/appStoreVersions`).
    func appStoreVersionReleases(appID: String) async throws -> [AppStoreConnectResource<AppStoreVersionReleaseAttributes>] {
        try await allPages(of: "/v1/apps/\(appID)/appStoreVersions", query: [Self.pageLimit])
    }

    /// One app info with its rating and category linkages
    /// (`GET /v1/appInfos/{id}?include=primaryCategory,…`).
    func appInfoDetail(appInfoID: String) async throws -> AppInformationResourceDocument<AppInfoRatingAttributes>.Resource? {
        let include = ["primaryCategory", "secondaryCategory", "primarySubcategoryOne", "primarySubcategoryTwo"].joined(separator: ",")
        let document: AppInformationResourceDocument<AppInfoRatingAttributes> = try await get(
            url("/v1/appInfos/\(appInfoID)", query: [URLQueryItem(name: "include", value: include)])
        )
        return document.data
    }

    /// The app info's questionnaire (`GET /v1/appInfos/{id}/ageRatingDeclaration`).
    func ageRatingDeclaration(appInfoID: String) async throws -> AppInformationResourceDocument<AgeRatingDeclarationAttributes>.Resource? {
        try await optional("/v1/appInfos/\(appInfoID)/ageRatingDeclaration")
    }

    /// The version's review details; nil when it has none yet
    /// (`GET /v1/appStoreVersions/{id}/appStoreReviewDetail`).
    func appStoreReviewDetail(versionID: String) async throws -> AppInformationResourceDocument<AppStoreReviewDetailAttributes>.Resource? {
        try await optional("/v1/appStoreVersions/\(versionID)/appStoreReviewDetail")
    }

    /// The build attached to the version; nil when none is
    /// (`GET /v1/appStoreVersions/{id}/build`).
    func versionBuild(versionID: String) async throws -> AppInformationResourceDocument<BuildEncryptionAttributes>.Resource? {
        try await optional("/v1/appStoreVersions/\(versionID)/build")
    }

    /// Export compliance declarations made in App Store Connect
    /// (`GET /v1/appEncryptionDeclarations?filter[app]={id}`). Apple no
    /// longer serves the app's `appEncryptionDeclarations` relationship.
    func appEncryptionDeclarations(appID: String) async throws -> [AppStoreConnectResource<AppEncryptionDeclarationAttributes>] {
        try await allPages(of: "/v1/appEncryptionDeclarations", query: [URLQueryItem(name: "filter[app]", value: appID), Self.pageLimit])
    }

    /// A to-one resource that may not exist: `data: null` or a 404 is nil.
    private func optional<Attributes>(_ path: String) async throws -> AppInformationResourceDocument<Attributes>.Resource? {
        do {
            let document: AppInformationResourceDocument<Attributes> = try await get(url(path))
            return document.data
        } catch AppStoreConnectError.notFound {
            return nil
        }
    }
}
