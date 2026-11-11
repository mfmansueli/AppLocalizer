//
//  ProLinks.swift
//  AppLocalizer
//

import Foundation

/// The links the paywall always shows, which App Review checks for
/// subscriptions (guideline 3.1.2).
enum ProLinks {
    /// Apple's standard license agreement, AppLocalizer's Terms of Use.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")

    /// AppLocalizer's privacy policy, from the Info.plist's
    /// `ALPrivacyPolicyURL`; nil until it's set, and then the link is left
    /// out. It has to be there before the paywall ships.
    static var privacyPolicy: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "ALPrivacyPolicyURL") as? String).flatMap(URL.init(string:))
    }
}
