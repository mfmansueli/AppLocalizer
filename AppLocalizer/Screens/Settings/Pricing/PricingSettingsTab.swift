//
//  PricingSettingsTab.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Pricing: the pricing mode new apps start in and the strategy
/// every subscription starts from (`AppPreferences.pricingDefaults`), plus
/// what the bundled index data is. Each subscription can still change its
/// own strategy in Pricing's inspector.
struct PricingSettingsTab: View {
    @Environment(AppPreferences.self) private var preferences
    @State private var snapshot = try? PriceIndexSnapshot.bundled()
    @State private var isEditingFallback = false
    @State private var isEditingLimits = false

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section("New apps") {
                Picker(selection: $preferences.defaultPricingMode) {
                    ForEach(PricingMode.allCases) { Text($0.title).tag($0) }
                } label: {
                    SettingsRowLabel(title: "Pricing mode for new apps", caption: String(localized: "Each app can still switch from its Pricing toolbar"))
                }
                .accessibilityIdentifier("settings.pricingMode")
                Toggle(isOn: $preferences.usesSalesData) {
                    SettingsRowLabel(
                        title: "Use sales data for suggestions",
                        caption: String(localized: "Sales and Trends and App Analytics, when the key’s role can read them")
                    )
                }
                .toggleStyle(.switch)
                Picker("Base territory", selection: baseTerritory) {
                    ForEach(Self.territories) { territory in
                        Text(verbatim: "\(territory.name) · \(territory.currencyCode)").tag(territory.id)
                    }
                }
                Picker("Rounding", selection: strategy(\.rounding)) {
                    ForEach(PriceRounding.allCases, id: \.self) { Text(Self.title(for: $0)).tag($0) }
                }
            }
            indexDefaults
            indexData
        }
        .formStyle(.grouped)
    }

    private var indexDefaults: some View {
        Section("Price index defaults") {
            Picker("Default source", selection: strategy(\.indexSource)) {
                ForEach(PriceIndexSource.allCases.filter { $0 != .custom }) { Text($0.name).tag($0) }
            }
            .accessibilityIdentifier("settings.indexSource")
            LabeledContent {
                Button("Edit…") { isEditingFallback = true }
                    .popover(isPresented: $isEditingFallback, arrowEdge: .trailing) {
                        FallbackChainEditor(strategy: strategyBinding)
                    }
            } label: {
                SettingsRowLabel(title: "Fallback chain", caption: fallbackSummary)
            }
            LabeledContent("Intensity") {
                HStack(spacing: Spacing.medium) {
                    Slider(value: intensity, in: 0...100)
                        .frame(width: 180)
                        .labelsHidden()
                    Text(verbatim: "\(Int(intensity.wrappedValue))%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
            Toggle(isOn: strategy(\.discountOnly)) {
                SettingsRowLabel(title: "Discount only", caption: String(localized: "Never above Apple’s equalized price"))
            }
            .toggleStyle(.switch)
            LabeledContent {
                HStack(spacing: Spacing.medium) {
                    Text(verbatim: "\(defaults.floor.percentText)% · \(defaults.ceiling.percentText)%")
                        .foregroundStyle(Palette.label2)
                        .monospacedDigit()
                    Button("Edit…") { isEditingLimits = true }
                        .popover(isPresented: $isEditingLimits, arrowEdge: .trailing) {
                            PriceLimitsEditor(strategy: strategyBinding)
                        }
                }
            } label: {
                Text("Floor · ceiling, relative to base")
            }
            Toggle(isOn: strategy(\.neverRaise)) {
                SettingsRowLabel(title: "Never raise existing prices", caption: String(localized: "Applies to every strategy"))
            }
            .toggleStyle(.switch)
            if defaults.isCustom {
                Button("Restore Recommended Defaults") { preferences.pricingDefaults.resetToRecommended() }
                    .accessibilityIdentifier("settings.restoreRecommended")
            }
        }
    }

    private var indexData: some View {
        Section("Index data") {
            LabeledContent {
                Text("Works offline")
                    .foregroundStyle(Palette.label2)
            } label: {
                SettingsRowLabel(title: "Bundled snapshot", caption: snapshotSummary)
            }
            if snapshot?.isApproximate == true {
                Text("The bundled values are approximate sample data, not the publishers’ figures. New editions arrive with app updates.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
        }
    }

    // MARK: - Values

    private static let territories = TerritoryCatalog.standard.territories.sorted { $0.name < $1.name }

    private var defaults: PricingStrategy { preferences.pricingDefaults }

    /// "World Bank → region median → equalized".
    private var fallbackSummary: String {
        defaults.resolutionChain.map { step in
            switch step {
            case let .index(source): source.shortName
            case .regionMedian: String(localized: "region median")
            case .equalized: String(localized: "equalized")
            }
        }
        .joined(separator: " → ")
    }

    /// "Apr 30, 2026 · Big Mac Jan 2026 · World Bank 2024 · IMF Apr 2026".
    private var snapshotSummary: String {
        guard let snapshot else { return String(localized: "Couldn’t read the bundled index data") }
        let editions = [PriceIndexSource.bigMac, .worldBank, .imf].compactMap { source in
            snapshot.index(source).map { "\(source.shortName) \($0.edition.label)" }
        }
        return ([snapshot.snapshotDate.formatted(date: .abbreviated, time: .omitted)] + editions).joined(separator: " · ")
    }

    static func title(for rounding: PriceRounding) -> String {
        switch rounding {
        case .auto: String(localized: "Each currency’s usual ending")
        case .ninetyNine: String(localized: "Always .99")
        case .ninety: String(localized: "Always .90")
        case .round: String(localized: "Round numbers")
        }
    }

    // MARK: - Bindings

    private var strategyBinding: Binding<PricingStrategy> {
        Binding(get: { preferences.pricingDefaults }, set: { preferences.pricingDefaults = $0 })
    }

    /// Edits one setting the way Pricing's inspector does: changing anything
    /// on Recommended makes the defaults a custom price index.
    private func strategy<Value>(_ keyPath: WritableKeyPath<PricingStrategy, Value>) -> Binding<Value> {
        Binding(
            get: { preferences.pricingDefaults[keyPath: keyPath] },
            set: { value in preferences.pricingDefaults.customize { $0[keyPath: keyPath] = value } }
        )
    }

    /// The base territory isn't part of the method, so it stays Recommended.
    private var baseTerritory: Binding<String> {
        Binding(get: { preferences.pricingDefaults.baseTerritoryID }, set: { preferences.pricingDefaults.baseTerritoryID = $0 })
    }

    private var intensity: Binding<Double> {
        Binding(
            get: { NSDecimalNumber(decimal: preferences.pricingDefaults.intensity * 100).doubleValue },
            set: { value in preferences.pricingDefaults.customize { $0.intensity = Decimal(Int(value.rounded())) / 100 } }
        )
    }
}
