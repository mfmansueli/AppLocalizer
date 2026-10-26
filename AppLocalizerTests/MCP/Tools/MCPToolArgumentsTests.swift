//
//  MCPToolArgumentsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("MCPToolArguments")
struct MCPToolArgumentsTests {
    private let arguments = MCPToolArguments([
        "appId": " lumen ",
        "blank": "  ",
        "none": nil,
        "count": 3,
        "locales": ["de-DE", "fr-FR"],
        "locale": "ja",
        "mixed": ["de-DE", 1],
        "fields": ["subtitle": "Write it down"],
    ])

    @Test func stringsAreTrimmedAndBlankMeansAbsent() throws {
        #expect(try arguments.string("appId") == "lumen")
        #expect(try arguments.optionalString("blank") == nil)
        #expect(try arguments.optionalString("none") == nil)
        #expect(try arguments.optionalString("missing") == nil)
        #expect(throws: MCPToolError.invalidArgument(name: "blank", expected: "a string")) { try arguments.string("blank") }
        #expect(throws: MCPToolError.invalidArgument(name: "count", expected: "a string")) { try arguments.optionalString("count") }
    }

    @Test func stringListsAcceptOneString() throws {
        #expect(try arguments.optionalStrings("locales") == ["de-DE", "fr-FR"])
        #expect(try arguments.optionalStrings("locale") == ["ja"])
        #expect(try arguments.optionalStrings("missing") == nil)
        #expect(throws: MCPToolError.invalidArgument(name: "mixed", expected: "a list of strings")) { try arguments.optionalStrings("mixed") }
    }

    @Test func listsAndObjects() throws {
        #expect(try arguments.array("locales").count == 2)
        #expect(throws: MCPToolError.invalidArgument(name: "appId", expected: "a list")) { try arguments.array("appId") }
        #expect(try arguments.optionalObject("fields") == ["subtitle": "Write it down"])
        #expect(try arguments.optionalObject("none") == nil)
        #expect(throws: MCPToolError.invalidArgument(name: "count", expected: "an object")) { try arguments.optionalObject("count") }
    }

    @Test func errorsTellTheAssistantWhatToSend() {
        let error = MCPToolError.invalidArgument(name: "appId", expected: "a string")
        #expect(error.localizedDescription == "The argument “appId” must be a string.")
        #expect(MCPToolError.notFound("No app.").localizedDescription == "No app.")
        #expect(MCPToolError.unavailable("Offline.").localizedDescription == "Offline.")
    }
}
