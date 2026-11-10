//
//  AcceptAllCheckState.swift
//  AppLocalizer
//

import Foundation

/// A checkbox in the Accept All sheet; a group is mixed when only some of
/// its suggestions are ticked.
enum AcceptAllCheckState: Hashable, Sendable {
    case checked
    case mixed
    case unchecked
}
