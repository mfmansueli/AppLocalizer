//
//  AppStoreConnectPageLinks.swift
//  AppLocalizer
//

import Foundation

/// A collection page's `links`: `next` is the absolute URL of the following
/// page, already carrying the original query and a cursor.
struct AppStoreConnectPageLinks: Decodable, Sendable {
    var next: URL?
}
