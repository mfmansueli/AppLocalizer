//
//  PriceTileMapTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The map and histogram of Lumen Plus Annual once every territory follows
/// the recommended strategy, as the `pricing-map` and `pricing-hist`
/// scenes show them.
@MainActor
@Suite("PriceTileMap")
struct PriceTileMapTests {
    @Test func everyTerritoryHasATile() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        let map = matrix.tileMap(metric: .percentVsBase)
        #expect(map.tiles.count == 175)
        #expect(Set(map.tiles.map(\.cell)).count == 175)
        #expect(map.lowLabel == "−70%")
        #expect(map.highLabel == "+70%")
    }

    @Test func brazilIsHalfTheBasePrice() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        let brazil = try #require(matrix.tileMap(metric: .percentVsBase).tile(id: "BRA"))
        #expect(brazil.code == "BR")
        #expect(brazil.tone == .below)
        #expect(abs(brazil.value + 0.5) < 0.01)
        #expect(brazil.accessibilityLabel == "Brazil: R$ 109,90")
        let usa = try #require(matrix.tileMap(metric: .percentVsBase).tile(id: "USA"))
        #expect(usa.tone == .neutral)
        #expect(usa.colorShare == 0)
    }

    @Test func hoveringShowsBothPricesAndWhatTheyFeelLike() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        let detail = try #require(matrix.tileDetail(id: "BRA"))
        #expect(detail.title == "Brazil")
        #expect(detail.today == "R$ 219,90")
        #expect(detail.proposed == "R$ 109,90")
        #expect(detail.dollars == "$19.98 · −50% vs base")
        #expect(detail.feelsLike == "Feels like $40 · factor 0.50 · WB 2024")
    }

    @Test func withoutAProposalTheDetailShowsTodayOnly() async throws {
        let matrix = try await PricingModelFixtures.matrix()
        #expect(try #require(matrix.tileDetail(id: "BRA")).proposed == nil)
        #expect(matrix.tileDetail(id: "XXX") == nil)
    }

    @Test func oneWayMetricsUseTheAccentScale() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        let map = matrix.tileMap(metric: .dollars)
        #expect(map.tiles.allSatisfy { $0.tone == .scale })
        #expect(map.tiles.map(\.strength).min() == 0)
        #expect(map.tiles.map(\.strength).max() == 1)
        #expect(map.lowLabel.hasPrefix("$"))
        let factors = matrix.tileMap(metric: .indexFactor)
        #expect(factors.lowLabel.contains("."))
    }

    @Test func darkTilesUseLightText() {
        let tile = PriceTileMap.Tile(id: "BRA", code: "BR", cell: .init(row: 0, column: 0), value: -0.6, tone: .below, strength: 0.9, accessibilityLabel: "")
        #expect(tile.usesLightText)
        var pale = tile
        pale.strength = 0.2
        #expect(!pale.usesLightText)
    }

    @Test func theHistogramMatchesThePrototypesSummary() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        #expect(matrix.histogram.summary == "Median −50% vs equalized · 165 below · 10 at equalized · 0 above")
        #expect(matrix.histogram.buckets.reduce(0) { $0 + $1.count } == 175)
    }

    @Test func theHistogramFollowsTheFilters() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        matrix.filter.region = .europe
        #expect(matrix.histogram.buckets.reduce(0) { $0 + $1.count } == matrix.visibleRows.count)
        #expect(matrix.visibleRows.count < 175)
    }
}
#endif
