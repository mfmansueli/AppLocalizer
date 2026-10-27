//
//  SalesEvidence.swift
//  AppLocalizer
//

import Foundation

/// What a suggestion can know beyond purchasing power.
struct SalesEvidence: Hashable, Sendable {
    /// False when the key's role can't read Sales and Trends: every
    /// suggestion is then Low confidence, on purchasing power alone.
    var canReadSales: Bool
    /// This territory's last 28 days; nil when it sold too little to report.
    var signal: SalesSignal?
    /// The base territory's last 28 days, the conversion reference.
    var baseSignal: SalesSignal?
    var priorChange: PriorPriceChange?

    init(canReadSales: Bool, signal: SalesSignal? = nil, baseSignal: SalesSignal? = nil, priorChange: PriorPriceChange? = nil) {
        self.canReadSales = canReadSales
        self.signal = signal
        self.baseSignal = baseSignal
        self.priorChange = priorChange
    }

    /// A key that can't read sales.
    static let unavailable = SalesEvidence(canReadSales: false)
}
