//
//  TeamAccountTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("TeamAccount")
struct TeamAccountTests {
    @Test(arguments: [
        ("Northpier Studio", "NS"),
        ("brightline apps co", "BA"),
        ("Solo", "S"),
        ("Two-Words", "TW"),
        ("   ", "?"),
    ])
    func initialsTakeUpToTwoWords(name: String, initials: String) {
        #expect(TeamAccount(id: "K", name: name, role: "Admin").initials == initials)
    }
}
