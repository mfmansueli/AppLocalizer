//
//  CredentialsValidatorTests.swift
//  AppLocalizerTests
//

import CryptoKit
import Foundation
import Testing
@testable import AppLocalizer

@Suite("CredentialsValidator")
struct CredentialsValidatorTests {
    private let pem = P256.Signing.PrivateKey().pemRepresentation

    // MARK: - Issuer ID

    @Test(arguments: ["57246542-96fe-1a63-e053-0824d011072a", "  57246542-96FE-1A63-E053-0824D011072A\n"])
    func uuidIssuerIDsAreValid(issuerID: String) {
        #expect(CredentialsValidator.issuerIDIssue(issuerID) == nil)
    }

    @Test(arguments: ["", "57246542", "57246542-96fe-1a63-e053-0824d011072", "not a uuid"])
    func otherIssuerIDsAreInvalid(issuerID: String) {
        #expect(CredentialsValidator.issuerIDIssue(issuerID) == .invalidIssuerID)
    }

    // MARK: - Key ID

    @Test(arguments: ["2X9R4HXF34", " 2x9r4hxf34 "])
    func alphanumericKeyIDsAreValid(keyID: String) {
        #expect(CredentialsValidator.keyIDIssue(keyID) == nil)
    }

    @Test(arguments: ["", "2X9R-4HXF34", "2X9R 4HXF34", "ÄBCDE12345"])
    func otherKeyIDsAreInvalid(keyID: String) {
        #expect(CredentialsValidator.keyIDIssue(keyID) == .invalidKeyID)
    }

    // MARK: - Private key

    @Test func p256PKCS8KeyIsValid() {
        #expect(CredentialsValidator.privateKeyIssue(pem) == nil)
        #expect(CredentialsValidator.privateKeyIssue("\n\(pem)\n\n") == nil)
    }

    @Test(arguments: ["", "hello", "-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----"])
    func otherContentsAreUnreadable(contents: String) {
        #expect(CredentialsValidator.privateKeyIssue(contents) == .unreadablePrivateKey)
    }

    // Team keys are always P-256; anything else can't sign ES256 tokens.
    @Test func otherCurvesAreUnreadable() {
        let p384 = P384.Signing.PrivateKey().pemRepresentation
        #expect(CredentialsValidator.privateKeyIssue(p384) == .unreadablePrivateKey)
    }

    // MARK: - Credentials

    @Test func credentialsAreTrimmedAndNormalized() throws {
        let credentials = try #require(CredentialsValidator.credentials(
            issuerID: " 57246542-96FE-1A63-E053-0824D011072A ",
            keyID: " 2x9r4hxf34\n",
            privateKeyPEM: "\(pem)\n"
        ))
        #expect(credentials.issuerID == "57246542-96fe-1a63-e053-0824d011072a")
        #expect(credentials.keyID == "2X9R4HXF34")
        #expect(credentials.privateKeyPEM == pem.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test func anyIssueMeansNoCredentials() {
        #expect(CredentialsValidator.credentials(issuerID: "bad", keyID: TestKeys.keyID, privateKeyPEM: pem) == nil)
        #expect(CredentialsValidator.credentials(issuerID: TestKeys.issuerID, keyID: "", privateKeyPEM: pem) == nil)
        #expect(CredentialsValidator.credentials(issuerID: TestKeys.issuerID, keyID: TestKeys.keyID, privateKeyPEM: nil) == nil)
        #expect(CredentialsValidator.credentials(issuerID: TestKeys.issuerID, keyID: TestKeys.keyID, privateKeyPEM: "nope") == nil)
    }
}
