//
//  TemplateOperationApplierTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Proposals are `replace` operations on dotted paths, applied all or
/// nothing; every refusal says what to change.
@MainActor
@Suite("TemplateOperationApplier")
struct TemplateOperationApplierTests {
    private let applier = TemplateOperationApplier()

    private var template: ScreenshotTemplate {
        get throws { try ScreenshotTemplateJSONTests.decode() }
    }

    private func refusals(_ operations: [TemplateOperation]) throws -> [TemplateRefusal] {
        switch try applier.applying(operations, to: template) {
        case .success: []
        case let .failure(refusals): refusals.items
        }
    }

    @Test func aValidReplaceApplies() throws {
        let result = try applier.applying([.replace("caption.headline.size", with: 120)], to: template)
        let updated = try result.get()
        #expect(updated.caption.headline.size == 120)
        #expect(updated.version == 4)
    }

    @Test func aSlotOverrideApplies() throws {
        let result = try applier.applying([.replace("slots.2.over.caption.headline.size", with: 96)], to: template)
        #expect(try result.get().resolved(forSlot: 2).caption.headline.size == 96)
    }

    @Test func anUnknownPathIsRefusedWithTheFieldsBesideIt() throws {
        let items = try refusals([.replace("caption.headline.colour", with: "#FFFFFF")])
        let refusal = try #require(items.first)
        #expect(refusal.kind == .unknownPath)
        #expect(refusal.path == "caption.headline.colour")
        #expect(refusal.reason.contains("size"))
    }

    @Test func aValueOutOfRangeIsRefused() throws {
        let items = try refusals([.replace("caption.headline.maxLines", with: 7)])
        #expect(items.map(\.kind) == [.outOfRange])
        #expect(items.first?.reason.contains("7") == true)
    }

    @Test func theWrongTypeIsRefused() throws {
        let items = try refusals([.replace("device.width", with: "wide")])
        #expect(items.map(\.kind) == [.wrongType])
    }

    @Test func aSlotThatDoesntExistIsRefused() throws {
        let items = try refusals([.replace("slots.9.layout", with: "hero")])
        #expect(items.map(\.kind) == [.unknownSlot])
    }

    @Test func onlyReplaceIsSupported() throws {
        let items = try refusals([TemplateOperation(operation: "remove", path: "caption.headline.size", value: .null)])
        #expect(items.map(\.kind) == [.unsupportedOperation])
    }

    @Test func aFallbackThatCantDrawItsScriptIsRefused() throws {
        let items = try refusals([.replace("fonts.fallback.thai", with: "Hiragino Sans")])
        let refusal = try #require(items.first)
        #expect(refusal.kind == .fontCantDrawScript)
        #expect(refusal.reason.contains("Thai"))
    }

    @Test func aFontThatIsntInstalledIsRefused() throws {
        let items = try refusals([.replace("fonts.display", with: "No Such Font 4711")])
        #expect(items.map(\.kind) == [.unknownFont])
    }

    @Test func theSmallestSizeCantBeAboveTheSizeInAnySlot() throws {
        let items = try refusals([.replace("caption.headline.min", with: 108)])
        #expect(items.map(\.kind) == [.inconsistent])
        #expect(items.first?.path == "slots.1.over.caption.headline.min")
        #expect(items.first?.reason.contains("104") == true)
    }

    @Test func oneRefusalRefusesEveryOperation() throws {
        let result = try applier.applying(
            [.replace("caption.headline.size", with: 120), .replace("caption.headline.maxLines", with: 9)],
            to: template
        )
        guard case let .failure(refusals) = result else {
            Issue.record("Expected the operations to be refused")
            return
        }
        #expect(refusals.items.count == 1)
    }

    @Test func versionIsSetByAppLocalizer() throws {
        let items = try refusals([.replace("version", with: 9)])
        #expect(items.first?.kind == .unknownPath)
        #expect(items.first?.reason.contains("AppLocalizer") == true)
    }
}
