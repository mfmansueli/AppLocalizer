//
//  EnvironmentValues+AIProviderKeyChecker.swift
//  AppLocalizer
//

import SwiftUI

extension EnvironmentValues {
    /// How Settings → Translation checks the AI provider's key: the vendor
    /// by default, canned answers in DEBUG scenes.
    @Entry var aiProviderKeyChecker: any AIProviderKeyChecker = LiveAIProviderKeyChecker()
}
