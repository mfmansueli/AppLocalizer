//
//  ArtworkWebBlocking.swift
//  AppLocalizer
//

import Foundation
import WebKit

/// The content rules every Claude Design page renders under: nothing loads
/// from the network, only `al-asset:` files and data URIs, so a render
/// never depends on what's online and a page can't reach anywhere.
@MainActor
enum ArtworkWebBlocking {
    static let identifier = "applocalizer-artwork-offline"

    static let rules = """
    [
      {"trigger": {"url-filter": ".*"}, "action": {"type": "block"}},
      {"trigger": {"url-filter": "^al-asset:"}, "action": {"type": "ignore-previous-rules"}},
      {"trigger": {"url-filter": "^data:"}, "action": {"type": "ignore-previous-rules"}},
      {"trigger": {"url-filter": "^blob:"}, "action": {"type": "ignore-previous-rules"}},
      {"trigger": {"url-filter": "^about:"}, "action": {"type": "ignore-previous-rules"}}
    ]
    """

    private static var compiled: WKContentRuleList?

    /// The rules, compiled once.
    static func list() async throws -> WKContentRuleList {
        if let compiled { return compiled }
        guard let store = WKContentRuleListStore.default() else { throw ArtworkWebError.setupFailed }
        let list = try await store.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: rules)
        guard let list else { throw ArtworkWebError.setupFailed }
        compiled = list
        return list
    }
}
