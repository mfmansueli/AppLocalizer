//
//  KeyFileNameTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("KeyFileName")
struct KeyFileNameTests {
    @Test(arguments: [
        ("AuthKey_2X9R4HXF34.p8", "2X9R4HXF34"),
        ("AuthKey_2X9R4HXF34 (1).p8", "2X9R4HXF34"),
        ("AuthKey_2X9R4HXF34", "2X9R4HXF34"),
    ])
    func keyIDComesFromApplesFileName(fileName: String, keyID: String) {
        #expect(KeyFileName.keyID(from: fileName) == keyID)
    }

    @Test(arguments: ["key.p8", "AuthKey_.p8", "authkey_2X9R4HXF34.p8", "SubscriptionKey_2X9R4HXF34.p8"])
    func otherFileNamesGiveNothing(fileName: String) {
        #expect(KeyFileName.keyID(from: fileName) == nil)
    }
}
