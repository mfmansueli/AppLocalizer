//
//  LoadState.swift
//  AppLocalizer
//

import Foundation

/// Where something fetched from App Store Connect stands, for views that show
/// a skeleton, the value, or an error with "Try Again".
enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// Loaded or failed: nothing more is coming.
    var isSettled: Bool {
        switch self {
        case .loaded, .failed: true
        case .idle, .loading: false
        }
    }

    var errorMessage: String? {
        if case let .failed(message) = self { return message }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}
