//
//  AppReviewValues.swift
//  AppLocalizer
//

import Foundation

/// The App Review page's values for one version. The password is only ever
/// held in memory and in the Keychain; changes carry a placeholder for it.
struct AppReviewValues: Hashable, Sendable {
    var firstName = ""
    var lastName = ""
    var phone = ""
    var email = ""
    var signInRequired = false
    var userName = ""
    var password = ""
    var notes = ""

    /// The text of a text field; "" for the switch.
    func text(_ field: AppReviewField) -> String {
        switch field {
        case .firstName: firstName
        case .lastName: lastName
        case .phone: phone
        case .email: email
        case .signInRequired: ""
        case .userName: userName
        case .password: password
        case .notes: notes
        }
    }

    mutating func setText(_ text: String, for field: AppReviewField) {
        switch field {
        case .firstName: firstName = text
        case .lastName: lastName = text
        case .phone: phone = text
        case .email: email = text
        case .signInRequired: break
        case .userName: userName = text
        case .password: password = text
        case .notes: notes = text
        }
    }

    /// Contact filled in, and a demo account when sign-in is required.
    var isComplete: Bool {
        let contact = [firstName, lastName, phone, email].allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return contact && (!signInRequired || (!userName.isEmpty && !password.isEmpty))
    }
}
