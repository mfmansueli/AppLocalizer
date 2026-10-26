//
//  PrivacyProposalOutcome.swift
//  AppLocalizer
//

import Foundation

/// What one of an assistant's App Privacy answers did to the worksheet,
/// reported back per item by `propose_privacy_answers`.
enum PrivacyProposalOutcome: String, Hashable, Sendable {
    /// A new or different suggestion, waiting for review.
    case queued
    /// It differs from an answer the person gave; they pick one.
    case conflict
    /// The worksheet already says the same.
    case unchanged
}
