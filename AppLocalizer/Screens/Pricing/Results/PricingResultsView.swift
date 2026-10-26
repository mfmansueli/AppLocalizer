//
//  PricingResultsView.swift
//  AppLocalizer
//

import SwiftUI

/// The Results tab: nothing to compare yet, too early to tell, results
/// that need sales AppLocalizer can't read, or the before-and-after report.
struct PricingResultsView: View {
    let viewModel: PricingViewModel

    var body: some View {
        Group {
            if let model = viewModel.results {
                content(model)
            } else {
                loading
                    .task { await viewModel.loadResults() }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.results")
    }

    @ViewBuilder
    private func content(_ model: PriceResultsModel) -> some View {
        switch model.state {
        case .loading:
            loading
        case .noChanges:
            ContentUnavailableView {
                Label("No price changes to compare yet", systemImage: "chart.bar.xaxis")
            } description: {
                Text("""
                After you push new prices, AppLocalizer compares 28 days before and after each change: subscription \
                starts, conversion from product page views, and proceeds.
                """)
            }
            .accessibilityIdentifier("pricing.results.none")
        case let .tooEarly(changedOn, day, arrivesOn):
            ResultsWaitingView(changedOn: changedOn, day: day, arrivesOn: arrivesOn)
        case let .salesUnavailable(changedOn):
            ContentUnavailableView {
                Label("Results need sales data", systemImage: "chart.line.uptrend.xyaxis")
            } description: {
                Text("""
                Prices changed on \(PricingText.date(changedOn)). AppLocalizer doesn’t read Sales and Trends or App \
                Analytics yet, so it can’t compare subscription starts and proceeds before and after.
                """)
            }
            .accessibilityIdentifier("pricing.results.noSales")
        case let .ready(changedOn):
            ResultsReportView(model: model, changedOn: changedOn)
        case let .failed(message):
            ContentUnavailableView {
                Label("Results couldn’t load", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { viewModel.resultsDidChange() }
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("pricing.results.tryAgain")
            }
        }
    }

    private var loading: some View {
        ProgressView()
            .controlSize(.small)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
