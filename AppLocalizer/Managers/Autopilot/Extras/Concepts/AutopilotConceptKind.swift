//
//  AutopilotConceptKind.swift
//  AppLocalizer
//

import Foundation

/// What a concept of Claude Design's own is (Go freely): a place, a
/// viewpoint, or something else. The three differ in kind unless the
/// person's request says otherwise.
enum AutopilotConceptKind: String, Codable, CaseIterable, Hashable, Sendable {
    /// A landscape or setting.
    case place
    /// Seen through or from something.
    case viewpoint
    /// An object, an abstract treatment or an unexpected angle.
    case wildcard
}
