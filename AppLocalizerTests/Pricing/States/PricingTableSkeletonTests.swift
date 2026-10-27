//
//  PricingTableSkeletonTests.swift
//  AppLocalizerTests
//

import AppKit
import SwiftUI
import Testing
@testable import AppLocalizer

@MainActor
@Suite("PricingTableSkeleton")
struct PricingTableSkeletonTests {
    private let skeleton = NSHostingController(rootView: PricingTableSkeleton(columns: PriceColumnPreset.suggestions.columns))

    /// Its height feeds the window's minimum: rows that insisted on theirs
    /// crashed AppKit's layout under ⌘R's filter bar.
    @Test func shrinksToAShortWindow() {
        #expect(skeleton.sizeThatFits(in: CGSize(width: 900, height: 120)).height <= 120)
    }

    @Test func fillsTheHeightItIsGiven() {
        #expect(skeleton.sizeThatFits(in: CGSize(width: 900, height: 600)).height == 600)
    }
}
