//
//  EnvironmentValues+KeyChecker.swift
//  AppLocalizer
//

import SwiftUI

extension EnvironmentValues {
    /// How Connect and Settings → Account check keys: Apple by default,
    /// canned answers in DEBUG scenes.
    @Entry var keyChecker: any KeyChecker = LiveKeyChecker()
}
