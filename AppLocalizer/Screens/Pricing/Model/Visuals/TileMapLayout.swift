//
//  TileMapLayout.swift
//  AppLocalizer
//

import Foundation

/// One tile per territory on a 40 × 18 grid, placed near its longitude and
/// latitude; a tile whose cell is taken moves to the nearest free one. A
/// geographic map would hide Singapore, Luxembourg and the Caribbean.
struct TileMapLayout: Sendable {
    struct Cell: Hashable, Sendable {
        var row: Int
        var column: Int
    }

    static let columns = 40
    static let rows = 18

    /// The catalog's layout. Placement depends on order: earlier territories
    /// keep their natural cell.
    static let standard = TileMapLayout(territories: TerritoryCatalog.standard.territories)

    /// Cells by territory ID.
    let cells: [String: Cell]

    init(territories: [Territory]) {
        var occupied = Set<Cell>()
        var cells: [String: Cell] = [:]
        for territory in territories {
            let natural = Self.naturalCell(for: territory)
            let cell = Self.nearestFreeCell(to: natural, occupied: occupied) ?? natural
            occupied.insert(cell)
            cells[territory.id] = cell
        }
        self.cells = cells
    }

    subscript(territoryID: String) -> Cell? {
        cells[territoryID]
    }

    /// 9° of longitude per column, 7.6° of latitude per row from 76°N.
    static func naturalCell(for territory: Territory) -> Cell {
        let column = Int(((territory.longitude + 180) / 9).rounded(.down))
        let row = Int(((76 - territory.latitude) / 7.6).rounded(.down))
        return Cell(row: min(max(row, 0), rows - 1), column: min(max(column, 0), columns - 1))
    }

    /// Searches rings of growing radius; within a ring the closest cell wins,
    /// horizontal moves counting a little less than vertical ones.
    private static func nearestFreeCell(to origin: Cell, occupied: Set<Cell>) -> Cell? {
        for radius in 0..<10 {
            var best: (score: Double, cell: Cell)?
            for rowOffset in -radius...radius {
                for columnOffset in -radius...radius where max(abs(rowOffset), abs(columnOffset)) == radius {
                    let cell = Cell(row: origin.row + rowOffset, column: origin.column + columnOffset)
                    guard (0..<rows).contains(cell.row), (0..<columns).contains(cell.column), !occupied.contains(cell) else { continue }
                    let score = Double(rowOffset * rowOffset) + Double(columnOffset * columnOffset) * 0.8
                    if let current = best, current.score <= score { continue }
                    best = (score, cell)
                }
            }
            if let best { return best.cell }
        }
        return nil
    }
}
