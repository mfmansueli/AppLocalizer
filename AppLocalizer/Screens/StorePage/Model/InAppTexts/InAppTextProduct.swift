//
//  InAppTextProduct.swift
//  AppLocalizer
//

import Foundation

/// A subscription or in-app purchase whose display name and description
/// are localized in the In-App Texts matrix.
struct InAppTextProduct: Identifiable, Hashable, Sendable {
    /// The product ID, e.g. `lumen.plus.monthly`.
    let id: String
    /// The column title's first half, e.g. "Monthly".
    let referenceName: String
    let kind: InAppTextProductKind
}
