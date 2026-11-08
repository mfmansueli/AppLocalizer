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

    /// The newest 5-star reviews written in one storefront (`territory`, an
    /// alpha-3 code such as DEU), with the reviewer's nickname.
    func fiveStarReviews(appID: String, territory: String, limit: Int = 50) async throws -> [AppStoreConnectResource<CustomerReviewAttributes>] {
        let page: AppStoreConnectPage<CustomerReviewAttributes> = try await get(url("/v1/apps/\(appID)/customerReviews", query: [
            URLQueryItem(name: "filter[rating]", value: "5"),
            URLQueryItem(name: "filter[territory]", value: territory),
            URLQueryItem(name: "sort", value: "-createdDate"),
            URLQueryItem(name: "limit", value: String(min(limit, 200))),
            URLQueryItem(name: "fields[customerReviews]", value: "rating,title,body,territory,reviewerNickname"),
        ]))
        return page.data
    }
}
