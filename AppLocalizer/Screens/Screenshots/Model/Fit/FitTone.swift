//
//  FitTone.swift
//  AppLocalizer
//

import Foundation

/// How a caption fits, for the fit meter's color and its label.
enum FitTone: String, Hashable, Sendable {
    /// Fits at full size.
    case fits
    /// Fits once shrunk, above the smallest size.
    case shrinks
    /// Doesn't fit even at the smallest size.
    case overflows
    /// No text.
    case empty
}
