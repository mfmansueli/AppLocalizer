//
//  ScreenshotAPISingleDocument.swift
//  AppLocalizer
//

import Foundation

/// A response with one resource: what `POST /v1/appScreenshotSets`,
/// `POST /v1/appScreenshots` and `GET /v1/appScreenshots/{id}` return.
struct ScreenshotAPISingleDocument<Attributes: Decodable & Sendable>: Decodable, Sendable {
    var data: ScreenshotAPIResource<Attributes>
}
