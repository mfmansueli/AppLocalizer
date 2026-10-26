//
//  AppStoreReviewDetailAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `appStoreReviewDetails` attributes: who App Review contacts, the
/// demo account, and notes. One per version. The password is kept in
/// memory only; AppLocalizer stores what you type in the Keychain.
struct AppStoreReviewDetailAttributes: Decodable, Sendable {
    var contactFirstName: String?
    var contactLastName: String?
    var contactPhone: String?
    var contactEmail: String?
    var demoAccountName: String?
    var demoAccountPassword: String?
    var demoAccountRequired: Bool?
    var notes: String?
}
