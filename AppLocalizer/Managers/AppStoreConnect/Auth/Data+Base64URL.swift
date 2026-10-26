//
//  Data+Base64URL.swift
//  AppLocalizer
//

import Foundation

extension Data {
    /// Base64URL without padding (RFC 7515 §2), the encoding JWT segments use.
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
