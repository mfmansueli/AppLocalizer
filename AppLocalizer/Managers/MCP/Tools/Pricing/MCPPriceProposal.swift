//
//  MCPPriceProposal.swift
//  AppLocalizer
//

import Foundation

/// One price an assistant proposes for a territory, as `propose_prices`
/// takes it.
struct MCPPriceProposal: Hashable, Sendable {
    /// The territory as the assistant wrote it: a code or a name.
    var territory: String
    /// In the territory's currency.
    var price: Decimal

    init(territory: String, price: Decimal) {
        self.territory = territory
        self.price = price
    }

    init(_ arguments: MCPToolArguments) throws {
        territory = try arguments.string("territory")
        guard let value = arguments.values["price"], let price = MCPPriceValue.decimal(from: value) else {
            throw MCPToolError.invalidArgument(name: "price", expected: String(localized: "a positive price in the territory’s currency, e.g. 109.9"))
        }
        self.price = price
    }

    /// The proposals in a call: `prices: [{territory, price}]`, or one
    /// `territory` and `price`.
    static func list(from arguments: MCPToolArguments) throws -> (proposals: [MCPPriceProposal], isBatch: Bool) {
        guard let items = try arguments.optionalArray("prices") else { return try ([MCPPriceProposal(arguments)], false) }
        let expected = String(localized: "a non-empty list of {territory, price} objects")
        guard !items.isEmpty else { throw MCPToolError.invalidArgument(name: "prices", expected: expected) }
        let proposals = try items.map { item in
            guard let object = item.objectValue else { throw MCPToolError.invalidArgument(name: "prices", expected: expected) }
            return try MCPPriceProposal(MCPToolArguments(object))
        }
        return (proposals, true)
    }

    /// Why a territory wasn't found.
    static func unknownTerritoryMessage(_ identifier: String, product: PricingProduct) -> String {
        String(localized: """
        “\(identifier)” isn’t a territory \(product.name) is sold in. Use App Store Connect’s three-letter code \
        (BRA) or the two-letter one (BR), as get_prices lists them.
        """)
    }
}
