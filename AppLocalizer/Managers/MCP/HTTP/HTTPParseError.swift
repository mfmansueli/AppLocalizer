//
//  HTTPParseError.swift
//  AppLocalizer
//

import Foundation

/// Why bytes from a client couldn't be read as a request. The connection
/// answers with `statusCode` and closes.
enum HTTPParseError: Error, Equatable {
    case malformed
    case headersTooLarge
    case bodyTooLarge
    case unsupportedTransferEncoding

    var statusCode: Int {
        switch self {
        case .malformed: 400
        case .headersTooLarge: 431
        case .bodyTooLarge: 413
        case .unsupportedTransferEncoding: 501
        }
    }
}
