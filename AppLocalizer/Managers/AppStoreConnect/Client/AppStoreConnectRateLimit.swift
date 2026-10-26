//
//  AppStoreConnectRateLimit.swift
//  AppLocalizer
//

import Foundation

/// App Store Connect's hourly request quota, read from the `X-Rate-Limit`
/// header every response carries: `user-hour-lim:3600;user-hour-rem:3143;`.
struct AppStoreConnectRateLimit: Hashable, Sendable {
    var limit: Int
    var remaining: Int

    static let defaultHourlyLimit = 3600

    var used: Int { max(0, limit - remaining) }

    /// Share of the hour's quota already used, 0…1.
    var fractionUsed: Double {
        limit > 0 ? min(1, Double(used) / Double(limit)) : 0
    }

    init(limit: Int, remaining: Int) {
        self.limit = limit
        self.remaining = remaining
    }

    /// Parses the header value; nil when it's missing or malformed.
    init?(header: String?) {
        guard let header else { return nil }
        var values: [String: Int] = [:]
        for pair in header.split(separator: ";") {
            let parts = pair.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let value = Int(parts[1]) { values[parts[0]] = value }
        }
        guard let limit = values["user-hour-lim"], let remaining = values["user-hour-rem"] else { return nil }
        self.init(limit: limit, remaining: remaining)
    }
}
