//
//  FakeAIProviderKeyChecker.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Records which keys were checked and answers with `error` or a passing
/// check; `waitsForCancellation` keeps the check running until its task is
/// cancelled.
@MainActor
final class FakeAIProviderKeyChecker: AIProviderKeyChecker {
    var error: (any Error)?
    var waitsForCancellation = false
    /// The keys checked, and for which vendor.
    private(set) var checkedKeys: [String] = []
    private(set) var checkedVendors: [AIProviderVendor] = []
    /// Waiting for the first check to start.
    private var waiting: [CheckedContinuation<Void, Never>] = []

    static let checkedAt = Date(timeIntervalSince1970: 1_800_000_000)

    nonisolated func check(_ apiKey: String, for vendor: AIProviderVendor) async throws -> AIProviderKeyCheck {
        try await answer(apiKey, vendor)
    }

    /// Returns once a check has started, without spinning the main actor
    /// the other tests share.
    func waitForACheck() async {
        guard checkedKeys.isEmpty else { return }
        await withCheckedContinuation { waiting.append($0) }
    }

    private func answer(_ apiKey: String, _ vendor: AIProviderVendor) async throws -> AIProviderKeyCheck {
        checkedKeys.append(apiKey)
        checkedVendors.append(vendor)
        let started = waiting
        waiting = []
        started.forEach { $0.resume() }
        if waitsForCancellation { try await Task.sleep(for: .seconds(3600)) }
        if let error { throw error }
        return AIProviderKeyCheck(vendor: vendor, milliseconds: 182, date: Self.checkedAt)
    }
}
