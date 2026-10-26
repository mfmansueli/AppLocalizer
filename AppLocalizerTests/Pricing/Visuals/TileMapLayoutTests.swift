//
//  TileMapLayoutTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("TileMapLayout")
struct TileMapLayoutTests {
    private let layout = TileMapLayout.standard

    @Test func everyTerritoryGetsItsOwnCell() {
        #expect(layout.cells.count == 175)
        #expect(Set(layout.cells.values).count == 175)
    }

    @Test func cellsStayOnTheGrid() {
        #expect(layout.cells.values.allSatisfy { (0..<TileMapLayout.rows).contains($0.row) && (0..<TileMapLayout.columns).contains($0.column) })
    }

    @Test func firstTerritoryKeepsItsNaturalCell() throws {
        let first = try #require(PricingFixtures.catalog.territories.first)
        #expect(layout[first.id] == TileMapLayout.naturalCell(for: first))
    }

    @Test func naturalCellFollowsLongitudeAndLatitude() throws {
        let brazil = try PricingFixtures.territory("BR")
        #expect(TileMapLayout.naturalCell(for: brazil) == TileMapLayout.Cell(row: 11, column: 14))
        var north = brazil
        north.latitude = 89
        north.longitude = 179
        #expect(TileMapLayout.naturalCell(for: north) == TileMapLayout.Cell(row: 0, column: 39))
    }

    @Test func crowdedTerritoriesMoveToTheNearestFreeCell() throws {
        let brazil = try PricingFixtures.territory("BR")
        var twin = brazil
        twin.id = "TWN-TEST"
        let crowded = TileMapLayout(territories: [brazil, twin])
        let natural = TileMapLayout.naturalCell(for: brazil)
        let moved = try #require(crowded[twin.id])
        #expect(crowded[brazil.id] == natural)
        #expect(moved != natural)
        #expect(abs(moved.row - natural.row) <= 1 && abs(moved.column - natural.column) <= 1)
        #expect(moved.row == natural.row)
    }
}
