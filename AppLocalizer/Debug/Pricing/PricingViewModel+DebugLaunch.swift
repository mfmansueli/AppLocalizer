//
//  PricingViewModel+DebugLaunch.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension PricingViewModel {
    /// Brings a DEBUG scene to its starting state through the same calls a
    /// person's clicks make. Does nothing outside DEBUG scenes.
    func applyDebugLaunch(from services: any PricingServices) async {
        guard let launch = (services as? DebugPricingServices)?.launch else { return }
        if let today = launch.today { self.today = { today } }
        if let productID = launch.productID { await select(productID: productID) }
        applyDebugStrategy(launch)
        if let matrix {
            await applyDebugEdits(launch, to: matrix)
        }
        await applyDebugViews(launch)
        if launch.showsImport {
            let prices = matrix?.sheet.prices
            strategy.previewImport(text: PricingSampleData.customIndexCSV, fileName: PricingSampleData.customIndexFileName) { territory in
                prices?[territory.id]?.equalizationMultiplier
            }
        }
        if launch.refreshes {
            Task { await reload() }
        }
    }

    private func applyDebugStrategy(_ launch: PricingDebugLaunch) {
        if let strategy = launch.strategy {
            self.strategy.replace(with: strategy)
            strategyDidChange()
        }
        strategy.collapsedSections = launch.collapsedSections
        if let tab = launch.inspectorTab {
            inspectorTab = tab
            isInspectorPresented = true
        }
    }

    /// The tab, view, offer and sheet a scene shows.
    private func applyDebugViews(_ launch: PricingDebugLaunch) async {
        if let display = launch.display { self.display = display }
        hoveredTerritoryID = launch.hoveredTerritory
        if let offerID = launch.offerID {
            await loadOffers()
            selectedOfferID = offerID
        }
        if let tab = launch.tab { self.tab = tab }
        if launch.showsSchedule {
            await loadSubscribers()
            isScheduleSheetPresented = true
        }
    }

    private func applyDebugEdits(_ launch: PricingDebugLaunch, to matrix: PriceMatrixModel) async {
        matrix.filter.region = launch.region
        if launch.follows {
            followedProductIDs.insert(matrix.product.id)
            await matrix.follow()
        }
        if !launch.appliedSuggestions.isEmpty {
            await matrix.applySuggestion(to: launch.appliedSuggestions)
        }
        for (territoryID, price) in launch.manualPrices.sorted(by: { $0.key < $1.key }) {
            await matrix.setPrice(territoryID, to: price)
        }
        if let schedule = launch.schedule { matrix.setSchedule(schedule) }
        matrix.selection = Set(launch.selection)
        matrix.popover = launch.popover
    }
}
#endif
