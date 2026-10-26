//
//  SetsColumns.swift
//  AppLocalizer
//

import CoreGraphics

/// The Sets matrix's column widths: the locale, the read-only Preview,
/// then one column per slot as wide as a thumbnail plus its badge's
/// overhang.
struct SetsColumns: Hashable, Sendable {
    var thumbnailWidth: CGFloat
    var thumbnailHeight: CGFloat
    var slotCount: Int

    static let leading: CGFloat = 20
    static let locale: CGFloat = 200
    static let preview: CGFloat = 76
    static let slotSpacing: CGFloat = 0

    var slot: CGFloat { thumbnailWidth + 18 }

    /// Everything, for the scroll view's content width.
    var total: CGFloat {
        Self.leading + Self.locale + Self.preview + CGFloat(slotCount) * slot + Self.leading
    }

    /// The Preview tile: a little smaller than a thumbnail.
    var previewWidth: CGFloat { (thumbnailWidth * 0.8).rounded() }

    var previewHeight: CGFloat { (thumbnailHeight * 0.8).rounded() }
}
