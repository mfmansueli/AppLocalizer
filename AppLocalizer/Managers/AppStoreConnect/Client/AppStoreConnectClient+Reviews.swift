//
//  AppStoreConnectClient+Reviews.swift
//  AppLocalizer
//

import Foundation

extension AppStoreConnectClient {
    /// The newest reviews first, one page of up to 200.
    func customerReviews(appID: String, limit: Int = 200) async throws -> [AppStoreConnectResource<CustomerReviewAttributes>] {
        let page: AppStoreConnectPage<CustomerReviewAttributes> = try await get(url("/v1/apps/\(appID)/customerReviews", query: [
            URLQueryItem(name: "sort", value: "-createdDate"),
            URLQueryItem(name: "limit", value: String(min(limit, 200))),
            URLQueryItem(name: "fields[customerReviews]", value: "rating,title,body,territory"),
        ]))
        return page.data
    }
}
