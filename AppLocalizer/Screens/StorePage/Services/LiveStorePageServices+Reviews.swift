//
//  LiveStorePageServices+Reviews.swift
//  AppLocalizer
//

import Foundation

extension LiveStorePageServices {
    func customerReviews(for app: StoreApp, limit: Int) async throws -> [CustomerReview] {
        try await client.customerReviews(appID: app.id, limit: limit).map { resource in
            CustomerReview(rating: resource.attributes.rating ?? 0, title: resource.attributes.title ?? "", body: resource.attributes.body ?? "")
        }
    }
}
