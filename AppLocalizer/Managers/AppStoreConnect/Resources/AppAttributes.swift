//
//  AppAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `apps` resource attributes AppLocalizer asks for (`fields[apps]`).
struct AppAttributes: Decodable, Sendable {
    var name: String
    var bundleId: String
    var sku: String?
    var primaryLocale: String?
}
