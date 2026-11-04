//
//  ProductPageTestAskingStepTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What the Product Page Optimization sheet lists while it waits for the
/// variant: asked, read, designing, rendering in every language, each done,
/// going on or still to come.
@Suite("Product Page Optimization steps")
struct ProductPageTestAskingStepTests {
    private let asked = Date(timeIntervalSince1970: 1_800_000_000)

    private func steps(_ request: ArtworkVariantRequest, direction: String? = "Calm Paper") -> [ProductPageTestAskingStep] {
        ProductPageTestAskingStep.steps(for: request, assistant: "Claude Code", placement: "search results", direction: direction, languageCount: 14)
    }

    @Test func justAskedItWaitsForTheAssistantToRead() {
        let list = steps(ArtworkVariantRequest(role: .search, kind: .search, askedAt: asked))
        #expect(list.map(\.id) == ["asked", "read", "design", "render"])
        #expect(list.map(\.state) == [.done, .current, .upcoming, .upcoming])
        #expect(list[0].title == "Asked Claude Code for the Outcome search results image")
        #expect(list[0].detail?.hasPrefix("One idea changed: Interface → Outcome; the rest stays") == true)
        #expect(list[1].title == "Waiting for Claude Code to read what to change")
        #expect(list[2].title == "Claude Code designs it")
        #expect(list[3].title == "AppLocalizer renders it in 14 languages and checks it")
    }

    @Test func onceReadItsDesigningWithTheDirection() {
        var request = ArtworkVariantRequest(role: .search, kind: .search, askedAt: asked)
        request.readAt = asked.addingTimeInterval(20)
        let list = steps(request)
        #expect(list.map(\.state) == [.done, .done, .current, .upcoming])
        #expect(list[1].title == "Claude Code read what to change")
        #expect(list[2].title == "Claude Code is designing it")
        #expect(list[2].detail?.hasPrefix("Keeps Calm Paper’s colours, type and captures; shows the feeling or result of using it") == true)
        #expect(steps(request, direction: nil)[2].detail?.hasPrefix("Keeps the colours, type and captures") == true)
    }

    @Test func onceSentItRendersLanguageByLanguage() {
        var request = ArtworkVariantRequest(role: .search, kind: .search, askedAt: asked)
        request.readAt = asked.addingTimeInterval(20)
        request.receivedAt = asked.addingTimeInterval(200)
        request.languageCount = 12
        request.renderedCount = 5
        let list = steps(request)
        #expect(list.map(\.state) == [.done, .done, .done, .current])
        #expect(list[2].title == "Claude Code sent the Outcome image")
        #expect(list[3].title == "Rendering and checking it in 12 languages", "The run's own count wins")
        #expect(list[3].detail == "5 of 12 done · Apple’s rules, safe area and contrast")
    }

    /// VoiceOver hears each step's state first: macOS drops a value set on
    /// a group, so it's in the label.
    @MainActor
    @Test func eachStepSaysItsStateFirst() {
        var request = ArtworkVariantRequest(role: .search, kind: .search, askedAt: asked)
        request.readAt = asked.addingTimeInterval(20)
        let labels = steps(request).map(ProductPageTestAskingView.accessibilityLabel(of:))
        #expect(labels[1].hasPrefix("Done: Claude Code read what to change, "))
        #expect(labels[2].hasPrefix("In progress: Claude Code is designing it, Keeps Calm Paper’s colours"))
        #expect(labels[3].hasPrefix("Not yet: "))
    }
}
