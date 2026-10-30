//
//  DebugAIProviderKeyChecker.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// An `AIProviderKeyChecker` for DEBUG scenes: takes any key after `delay`
/// (so "checking…" is visible) except `rejectedKey`, which the vendor
/// refuses with a 401.
struct DebugAIProviderKeyChecker: AIProviderKeyChecker {
    static let rejectedKey = "sk-ant-revoked"

    var delay: Duration = .milliseconds(300)

    func check(_ apiKey: String, for vendor: AIProviderVendor) async throws -> AIProviderKeyCheck {
        try await Task.sleep(for: delay)
        if apiKey == Self.rejectedKey { throw AIProviderError.unauthorized(vendor) }
        return AIProviderKeyCheck(vendor: vendor, milliseconds: 182, date: .now)
    }
}
#endif
