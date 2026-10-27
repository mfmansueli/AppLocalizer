//
//  MCPClientSessionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("MCPClientSession")
struct MCPClientSessionTests {
    @Test func knownClientsGetTheirProductName() {
        #expect(MCPClientSession.displayName(clientName: "claude-code", title: nil) == "Claude Code")
        #expect(MCPClientSession.displayName(clientName: "zed", title: "Zed") == "Zed")
        #expect(MCPClientSession.displayName(clientName: "zed", title: nil) == "zed")
    }

    @Test func projectFoldersAreShownRelativeToHome() {
        let home = "/Users/sam"
        #expect(MCPClientSession.displayPath(forRootURI: "file:///Users/sam/Developer/Lumen", homeDirectory: home) == "~/Developer/Lumen")
        #expect(MCPClientSession.displayPath(forRootURI: "file:///Users/sam/My%20App", homeDirectory: home + "/") == "~/My App")
        #expect(MCPClientSession.displayPath(forRootURI: "file:///Users/sam", homeDirectory: home) == "~")
        #expect(MCPClientSession.displayPath(forRootURI: "file:///Users/samuel/Lumen", homeDirectory: home) == "/Users/samuel/Lumen")
        #expect(MCPClientSession.displayPath(forRootURI: "file:///Volumes/Work/Lumen", homeDirectory: home) == "/Volumes/Work/Lumen")
        #expect(MCPClientSession.displayPath(forRootURI: "https://example.com/Lumen", homeDirectory: home) == nil)
    }

    @Test func pairedClientsKeepTheirTokenUnderTheirOwnName() {
        let id = UUID()
        let client = MCPPairedClient(id: id, kind: .cursor, name: "Cursor", pairedAt: .now)
        #expect(client.secretName == "mcp.client.\(id.uuidString)")
        #expect(client.monogram == "CU")
    }

    @Test func statusReadsTheWaySettingsShowsIt() {
        let date = Date(timeIntervalSince1970: 1_792_000_000)
        #expect(MCPPairedClientStatus.idle(since: date, everConnected: false).text == "Paired · not connected yet")
        #expect(MCPPairedClientStatus.connected(lastCall: date).text.hasPrefix("Connected · last call "))
        #expect(MCPPairedClientStatus.disconnected(lastSeen: date).text.hasPrefix("Disconnected · last seen "))
        #expect(MCPPairedClientStatus.idle(since: date, everConnected: true).text.hasPrefix("Paired · not connected since "))
        #expect(MCPPairedClientStatus.connected(lastCall: date).isConnected)
        #expect(!MCPPairedClientStatus.disconnected(lastSeen: date).isConnected)
    }
}
