//
//  CustomerReviewAttributes.swift
//  AppLocalizer
//

import Foundation

/// A `customerReviews` resource: what someone wrote on the App Store.
struct CustomerReviewAttributes: Decodable, Sendable {
    var rating: Int?
    var title: String?
    var body: String?
    var territory: String?
    var reviewerNickname: String?
}
