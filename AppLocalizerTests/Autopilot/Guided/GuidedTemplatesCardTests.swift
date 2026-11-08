//
//  GuidedTemplatesCardTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Look's "Start from templates" card: the first pick's first three
/// screens (board 21), three templates before any is picked.
@MainActor
@Suite("Guided look · the templates card")
struct GuidedTemplatesCardTests {
    @Test func onePickShowsItsFirstThreeScreens() {
        let slots = GuidedShotLookOptions.cardSlots(picks: [.arcade])
        #expect(slots.map(\.starter) == [.arcade, .arcade, .arcade])
        #expect(slots.map(\.slot) == [0, 1, 2])
    }

    @Test func morePicksShowTheFirstPicksScreens() {
        let slots = GuidedShotLookOptions.cardSlots(picks: [.cinema, .editorial])
        #expect(slots.map(\.starter) == [.cinema, .cinema, .cinema])
        #expect(slots.map(\.slot) == [0, 1, 2])
    }

    @Test func noPickShowsThreeTemplates() {
        let slots = GuidedShotLookOptions.cardSlots(picks: [])
        #expect(slots.count == 3)
        #expect(Set(slots.map(\.starter)).count == 3)
        #expect(slots.allSatisfy { $0.slot == 0 })
    }
}
#endif
