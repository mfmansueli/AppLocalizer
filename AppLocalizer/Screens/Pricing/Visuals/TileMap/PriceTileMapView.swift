//
//  PriceTileMapView.swift
//  AppLocalizer
//

import SwiftUI

/// The tile map: one 20 pt tile per territory, placed near where it is, so
/// Singapore and Luxembourg are as easy to spot as Brazil. Colored by % vs
/// base, USD equivalent, “feels like” or index factor; hovering a tile shows
/// its prices. Territories the filters hide are dimmed, and clicking one
/// selects it.
struct PriceTileMapView: View {
    @Bindable var viewModel: PricingViewModel
    let matrix: PriceMatrixModel

    static let tileSize: CGFloat = 20
    static let pitch: CGFloat = 22

    var body: some View {
        let map = matrix.tileMap(metric: viewModel.mapMetric)
        let visible = Set(matrix.visibleRows.map(\.id))
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(spacing: Spacing.medium) {
                    Picker("Color by", selection: $viewModel.mapMetric) {
                        ForEach(TileMapMetric.allCases) { metric in
                            Text(metric.title).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .fixedSize()
                    .accessibilityIdentifier("pricing.map.metric")
                    Spacer(minLength: Spacing.medium)
                    TileMapLegend(metric: map.metric, lowLabel: map.lowLabel, highLabel: map.highLabel)
                }
                .frame(width: mapSize.width)
                tiles(map, visible: visible)
                Text("""
                One tile per territory, placed near where it is, so Singapore and Luxembourg stay as easy to spot as Brazil. \
                Colors use proposed prices where there are any, otherwise current ones.
                """)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: 700, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.top, Spacing.small)
            .padding(.bottom, Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.tileMap")
    }

    private var mapSize: CGSize {
        CGSize(
            width: CGFloat(TileMapLayout.columns) * Self.pitch - (Self.pitch - Self.tileSize),
            height: CGFloat(TileMapLayout.rows) * Self.pitch - (Self.pitch - Self.tileSize)
        )
    }

    private func tiles(_ map: PriceTileMap, visible: Set<String>) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(map.tiles) { tile in
                PriceTileButton(
                    tile: tile,
                    isSelected: matrix.selection.contains(tile.id),
                    isDimmed: !visible.contains(tile.id),
                    onHover: { viewModel.hoveredTerritoryID = tile.id },
                    onSelect: {
                        matrix.selection = [tile.id]
                        viewModel.hoveredTerritoryID = tile.id
                    }
                )
                .offset(x: CGFloat(tile.cell.column) * Self.pitch, y: CGFloat(tile.cell.row) * Self.pitch)
            }
            if let id = shownDetailID, let tile = map.tile(id: id), let detail = matrix.tileDetail(id: id) {
                PriceTileDetailCard(detail: detail)
                    .offset(detailOffset(for: tile.cell))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: mapSize.width, height: mapSize.height, alignment: .topLeading)
        .onHover { isInside in
            if !isInside { viewModel.hoveredTerritoryID = nil }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Tile map, one tile per territory"))
    }

    /// The hovered tile, else the one selected territory.
    private var shownDetailID: String? {
        viewModel.hoveredTerritoryID ?? (matrix.selection.count == 1 ? matrix.selection.first : nil)
    }

    /// Beside the tile, kept inside the map.
    private func detailOffset(for cell: TileMapLayout.Cell) -> CGSize {
        let x = min(CGFloat(cell.column) * Self.pitch + 28, mapSize.width - PriceTileDetailCard.width)
        let y = max(0, min(CGFloat(cell.row) * Self.pitch - 8, mapSize.height - 96))
        return CGSize(width: x, height: y)
    }
}
