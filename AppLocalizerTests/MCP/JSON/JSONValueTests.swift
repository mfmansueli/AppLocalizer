//
//  JSONValueTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("JSONValue")
struct JSONValueTests {
    private struct Sample: Codable, Equatable {
        var name: String
        var count: Int
    }

    @Test func decodesEveryKindOfValue() throws {
        let text = #"{"a":null,"b":true,"c":3,"d":2.5,"e":"x","f":[1,"y"],"g":{"h":false}}"#
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(text.utf8))
        let expected: JSONValue = ["a": nil, "b": true, "c": 3, "d": .double(2.5), "e": "x", "f": [1, "y"], "g": ["h": false]]
        #expect(value == expected)
    }

    @Test func roundTripsThroughCompactSortedText() throws {
        let value: JSONValue = ["b": 1, "a": "x/y", "c": [nil, .double(0.5)]]
        #expect(value.jsonString() == #"{"a":"x/y","b":1,"c":[null,0.5]}"#)
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data(value.jsonString().utf8)) == value)
    }

    @Test func accessorsReadOnlyTheirKind() {
        let value: JSONValue = ["name": "Lumen", "count": 2, "ratio": .double(2.0), "half": .double(2.5), "on": true, "list": [1]]
        #expect(value["name"]?.stringValue == "Lumen")
        #expect(value["count"]?.intValue == 2)
        #expect(value["ratio"]?.intValue == 2)
        #expect(value["half"]?.intValue == nil)
        #expect(value["half"]?.doubleValue == 2.5)
        #expect(value["count"]?.doubleValue == 2)
        #expect(value["on"]?.boolValue == true)
        #expect(value["list"]?.arrayValue == [1])
        #expect(value["name"]?.intValue == nil)
        #expect(value["missing"] == nil)
        #expect(JSONValue.string("x")["key"] == nil)
        #expect(JSONValue.null.isNull)
    }

    @Test func encodesAnyEncodableValue() throws {
        let value = try JSONValue(encoding: Sample(name: "Lumen", count: 5))
        #expect(value == ["name": "Lumen", "count": 5])
    }
}
