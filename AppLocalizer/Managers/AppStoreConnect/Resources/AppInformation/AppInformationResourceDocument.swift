//
//  AppInformationResourceDocument.swift
//  AppLocalizer
//

import Foundation

/// A single-resource JSON:API response (`GET /v1/appInfos/{id}`,
/// `GET /v1/appStoreVersions/{id}/appStoreReviewDetail`), with the
/// relationship linkages the request included. `data` is nil when a to-one
/// endpoint has nothing to return.
struct AppInformationResourceDocument<Attributes: Decodable & Sendable>: Decodable, Sendable {
    struct Resource: Decodable, Sendable {
        var type: String
        var id: String
        var attributes: Attributes
        var relationships: [String: AppInformationLinkage]?

        /// The related resource's ID, e.g. `relationshipID("primaryCategory")`.
        func relationshipID(_ name: String) -> String? {
            relationships?[name]?.data?.id
        }
    }

    var data: Resource?
}
