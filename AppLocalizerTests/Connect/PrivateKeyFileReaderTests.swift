//
//  PrivateKeyFileReaderTests.swift
//  AppLocalizerTests
//

import CryptoKit
import Foundation
import Testing
@testable import AppLocalizer

@Suite("PrivateKeyFileReader")
struct PrivateKeyFileReaderTests {
    @Test func readsTheFileNameAndContents() throws {
        let pem = P256.Signing.PrivateKey().pemRepresentation
        let url = FileManager.default.temporaryDirectory.appending(path: "AuthKey_\(UUID().uuidString.prefix(8)).p8")
        try pem.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let key = try PrivateKeyFileReader.read(url)
        #expect(key.fileName == url.lastPathComponent)
        #expect(key.pem == pem)
    }

    @Test func missingFileThrows() {
        let url = FileManager.default.temporaryDirectory.appending(path: "missing-\(UUID().uuidString).p8")
        #expect(throws: (any Error).self) { try PrivateKeyFileReader.read(url) }
    }
}
