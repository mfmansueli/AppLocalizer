//
//  ConflictCheckTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ConflictCheck")
struct ConflictCheckTests {
    private let response = Data(#"{"data":{"attributes":{"subtitle":"Calm journal","empty":""}},"included":[{"attributes":{"customerPrice":219.9}}]}"#.utf8)

    @Test func readsStringsAndNumbersAlongTheKeyPath() {
        #expect(ConflictCheck(path: "/", keyPath: ["data", "attributes", "subtitle"]).value(in: response) == "Calm journal")
        #expect(ConflictCheck(path: "/", keyPath: ["included", "0", "attributes", "customerPrice"]).value(in: response) == "219.9")
    }

    @Test func missingAndEmptyValuesReadAsNil() {
        #expect(ConflictCheck(path: "/", keyPath: ["data", "attributes", "empty"]).value(in: response) == nil)
        #expect(ConflictCheck(path: "/", keyPath: ["data", "nope"]).value(in: response) == nil)
        #expect(ConflictCheck(path: "/", keyPath: ["included", "3"]).value(in: response) == nil)
        #expect(ConflictCheck(path: "/", keyPath: ["data"]).value(in: Data("not json".utf8)) == nil)
    }

    @Test func numbersCompareByValue() {
        let check = ConflictCheck(path: "/", keyPath: [], expected: "219.90")
        #expect(!check.differs(from: "219.9"))
        #expect(check.differs(from: "199.9"))
        #expect(ConflictCheck(path: "/", keyPath: [], expected: nil).differs(from: "x"))
        #expect(!ConflictCheck(path: "/", keyPath: [], expected: "Same").differs(from: "Same"))
    }

    @Test func formatsWhatTheRowShows() {
        #expect(ConflictValueFormat.text.display("Calm") == "Calm")
        #expect(ConflictValueFormat.text.display(nil) == "Empty")
        let real = ConflictValueFormat.currency(code: "BRL", localeIdentifier: "pt_BR").display("199.9")
        #expect(real.contains("199,90"))
        #expect(real.contains("R$"))
    }
}
