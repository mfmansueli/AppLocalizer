//
//  PrivacyChecklistStep.swift
//  AppLocalizer
//

import CryptoKit
import Foundation

/// One step of "Fill in App Store Connect", in the order the questionnaire
/// asks: Data collection, Select the data types, one step per collected
/// type, then Publish. The body is the plain text Copy puts on the
/// pasteboard.
struct PrivacyChecklistStep: Identifiable, Hashable, Sendable {
    /// e.g. "s1", "d-userId".
    var id: String
    /// e.g. "1", "3.2".
    var number: String
    var title: String
    var body: String
    /// A data type's step, indented under step 3.
    var isTypeStep = false
    var canCopy = true

    /// What a tick is stored as: the step and a digest of its text, so a
    /// tick no longer applies once the answer behind it changes.
    var checkKey: String {
        let digest = SHA256.hash(data: Data((id + "\n" + body).utf8))
        let hex = digest.prefix(6).map { String(format: "%02x", $0) }.joined()
        return "\(id)#\(hex)"
    }
}
