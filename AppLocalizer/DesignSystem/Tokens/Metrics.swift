//
//  Metrics.swift
//  AppLocalizer
//

import CoreGraphics

/// Fixed sizes from the design handoff ("Metrics"). Pointer metrics, not
/// 44 pt touch targets: this is a desktop app.
enum Metrics {
    static let sidebarWidth: CGFloat = 256
    static let inspectorWidth: CGFloat = 300
    static let tableRowHeight: CGFloat = 26
    static let tableHeaderHeight: CGFloat = 28
    /// Smallest window the layout is designed for.
    static let minimumWindowWidth: CGFloat = 860
    static let minimumWindowHeight: CGFloat = 560
    /// Overview cards wrap into as many columns as fit at this width.
    static let overviewCardMinimumWidth: CGFloat = 270
}
