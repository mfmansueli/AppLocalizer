//
//  AIProviderKeyStatusModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Settings → Translation's API key status: whether the selected vendor's
/// key is saved and what checking it found. The tab checks when it opens,
/// after a key is saved, when the vendor changes and on Check Again.
@MainActor
@Observable
final class AIProviderKeyStatusModel {
    private(set) var status: AIProviderKeyStatus = .notSaved

    private let checker: any AIProviderKeyChecker

    init(checker: any AIProviderKeyChecker) {
        self.checker = checker
    }

    /// Checks the selected vendor's saved key; with no key nothing is sent.
    /// A check cancelled by a newer one (the vendor changed, a new key)
    /// leaves the status to the newer one.
    func check(_ preferences: TranslationPreferences) async {
        let vendor = preferences.vendor
        let key: String?
        do {
            key = preferences.hasAPIKey ? try preferences.apiKey() : nil
        } catch {
            status = .unchecked(vendor, reason: error.localizedDescription)
            return
        }
        guard let key else {
            status = .notSaved
            return
        }
        status = .checking(vendor)
        do {
            let check = try await checker.check(key, for: vendor)
            guard !Task.isCancelled else { return }
            status = .connected(check)
        } catch {
            guard !Task.isCancelled else { return }
            status = AIProviderKeyStatus(vendor: vendor, error: error)
        }
    }
}
