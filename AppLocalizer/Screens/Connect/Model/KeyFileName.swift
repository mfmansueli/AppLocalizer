//
//  KeyFileName.swift
//  AppLocalizer
//

import Foundation

/// App Store Connect names downloaded keys `AuthKey_<KEYID>.p8`, so the
/// Key ID can be filled in from the file name. A browser's duplicate suffix
/// (`AuthKey_2X9R4HXF34 (1).p8`) is ignored.
enum KeyFileName {
    static func keyID(from fileName: String) -> String? {
        let name = (fileName as NSString).deletingPathExtension
        let prefix = "AuthKey_"
        guard name.hasPrefix(prefix) else { return nil }
        let keyID = String(name.dropFirst(prefix.count).prefix { $0.isASCII && ($0.isLetter || $0.isNumber) })
        return CredentialsValidator.keyIDIssue(keyID) == nil ? keyID : nil
    }
}
