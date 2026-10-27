//
//  ListingConflictChoice.swift
//  AppLocalizer
//

import Foundation

/// Which version to keep when you and an assistant both changed a field.
enum ListingConflictChoice: Hashable, Sendable {
    case yours
    case assistant
}
