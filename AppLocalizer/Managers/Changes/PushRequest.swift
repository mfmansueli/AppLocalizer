//
//  PushRequest.swift
//  AppLocalizer
//

import Foundation

/// One App Store Connect write that applies (part of) a pending change, built
/// by the section that made the change: e.g. `POST /v1/subscriptionPrices`
/// or `PATCH /v1/appStoreVersionLocalizations/{id}`. Review & Push sends
/// them one at a time, in order, and never needs to know what they mean.
struct PushRequest: Hashable, Codable, Sendable {
    enum Method: String, Codable, Sendable {
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    var method: Method
    /// Path under `https://api.appstoreconnect.apple.com`, e.g. `/v1/subscriptionPrices`.
    var path: String
    /// The JSON:API document to send, if any.
    var body: Data?

    /// A request whose body is `value` encoded as JSON.
    static func json(_ method: Method, _ path: String, _ value: some Encodable) throws -> PushRequest {
        try PushRequest(method: method, path: path, body: JSONEncoder().encode(value))
    }
}
