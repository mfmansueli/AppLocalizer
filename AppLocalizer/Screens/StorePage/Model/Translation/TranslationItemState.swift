//
//  TranslationItemState.swift
//  AppLocalizer
//

import Foundation

/// One cell's progress in a translation batch.
enum TranslationItemState: Hashable, Sendable {
    case queued
    case translating
    case done(String)
    /// With the provider's message.
    case failed(String)

    var isFinished: Bool {
        switch self {
        case .done, .failed: true
        case .queued, .translating: false
        }
    }
}
