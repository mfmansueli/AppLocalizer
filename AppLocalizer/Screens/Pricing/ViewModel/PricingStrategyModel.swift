//
//  PricingStrategyModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The app's pricing strategy and the index data it draws on, as the
/// Customize… inspector edits them. Any edit to the recommended strategy
/// turns it custom; `Back to Recommended` undoes all of them.
@MainActor
@Observable
final class PricingStrategyModel {
    private(set) var strategy: PricingStrategy
    private(set) var snapshot: PriceIndexSnapshot
    private(set) var calculator: PriceCalculator
    /// A picked CSV waiting for confirmation in the import sheet.
    var importPreview: CustomIndexPreview?
    var collapsedSections: Set<StrategyInspectorSection> = []
    /// Set after “Update Index Data”, to say what happened.
    private(set) var updateMessage: String?

    let territories: TerritoryCatalog

    init(
        territories: TerritoryCatalog = .standard,
        snapshot: PriceIndexSnapshot,
        commission: Commission,
        strategy: PricingStrategy = .recommended
    ) {
        self.territories = territories
        self.snapshot = snapshot
        self.strategy = strategy
        calculator = PriceCalculator(catalog: territories, snapshot: snapshot, commission: commission)
    }

    var commission: Commission { calculator.commission }

    var baseTerritory: Territory? { territories.territory(alpha3: strategy.baseTerritoryID) }

    // MARK: - Editing

    /// Applies an edit through `PricingStrategy.customize`, so the strategy turns custom.
    func edit(_ change: (inout PricingStrategy) -> Void) {
        var next = strategy
        next.customize(change)
        strategy = next
    }

    func resetToRecommended() {
        strategy.resetToRecommended()
    }

    func replace(with strategy: PricingStrategy) {
        self.strategy = strategy
    }

    func setCommission(_ commission: Commission) {
        guard commission != calculator.commission else { return }
        calculator = PriceCalculator(catalog: territories, snapshot: snapshot, commission: commission)
    }

    func toggleExclusion(of territoryID: String) {
        edit { strategy in
            if strategy.excludedTerritoryIDs.contains(territoryID) {
                strategy.excludedTerritoryIDs.remove(territoryID)
            } else {
                strategy.excludedTerritoryIDs.insert(territoryID)
            }
        }
    }

    func isCollapsed(_ section: StrategyInspectorSection) -> Bool {
        collapsedSections.contains(section)
    }

    func toggle(_ section: StrategyInspectorSection) {
        if collapsedSections.contains(section) {
            collapsedSections.remove(section)
        } else {
            collapsedSections.insert(section)
        }
    }

    // MARK: - Facts for the inspector

    var fallbackCount: Int { calculator.fallbackCount(strategy: strategy) }

    var tierCounts: [Int] { calculator.tierCounts(strategy: strategy) }

    func index(_ source: PriceIndexSource) -> PriceIndex? {
        snapshot.index(source)
    }

    // MARK: - Index data

    /// Parses a CSV for the import sheet; nothing changes until `confirmImport`.
    func previewImport(text: String, fileName: String, equalizationMultiplier: @escaping (Territory) -> Decimal? = { _ in nil }) {
        let result = CustomIndexCSV.parse(
            text,
            catalog: territories,
            baseTerritoryID: strategy.baseTerritoryID,
            equalizationMultiplier: equalizationMultiplier
        )
        let lines = text.components(separatedBy: .newlines).dropFirst().count { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        importPreview = CustomIndexPreview(fileName: fileName, lineCount: lines, result: result)
    }

    /// Adds the previewed index and switches the strategy to it.
    func confirmImport(on date: Date = .now) {
        guard let preview = importPreview, !preview.result.isEmpty else { return }
        snapshot = snapshot.adding(preview.result.index(fileName: preview.fileName, importedOn: date))
        calculator = PriceCalculator(catalog: territories, snapshot: snapshot, commission: calculator.commission)
        importPreview = nil
        edit { strategy in
            strategy.method = .priceIndex
            strategy.indexSource = .custom
        }
    }

    func cancelImport() {
        importPreview = nil
    }

    /// The index publishers have no API AppLocalizer can read, so the bundled
    /// snapshot is the newest data; say so instead of pretending to fetch.
    func updateIndexData() {
        let date = PricingText.date(snapshot.snapshotDate)
        updateMessage = String(localized: "You have the newest index data AppLocalizer bundles (\(date)). It’s approximate; new editions arrive with app updates.")
    }
}
