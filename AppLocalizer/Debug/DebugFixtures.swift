//
//  DebugFixtures.swift
//  AppLocalizer
//

#if DEBUG
import CryptoKit
import Foundation

/// Canned data for DEBUG scenes.
enum DebugFixtures {
    static let issuerID = "69a6de7f-1a2b-47e3-e053-5b8c7c11a4d1"
    static let keyID = "ABCDE12345"

    /// A freshly generated P-256 key in the same PKCS#8 PEM format as a
    /// downloaded `.p8`, named the way App Store Connect names them.
    static var privateKey: ImportedPrivateKey {
        ImportedPrivateKey(fileName: "AuthKey_\(keyID).p8", pem: P256.Signing.PrivateKey().pemRepresentation)
    }

    static let apps: [StoreApp] = [
        StoreApp(id: "6443000001", name: "Bruma", bundleID: "com.lima.bruma", sku: "BRUMA", primaryLocale: "en-US"),
        StoreApp(id: "6443000002", name: "Focus Timer", bundleID: "com.lima.focustimer", sku: "FOCUS", primaryLocale: "en-US"),
        StoreApp(id: "6443000003", name: "Receitas da Vó", bundleID: "com.lima.receitas", sku: "RECEITAS", primaryLocale: "pt-BR"),
        StoreApp(id: "6443000004", name: "Wanderlog", bundleID: "com.lima.wanderlog", sku: "WANDER", primaryLocale: "en-GB"),
    ]
}
#endif
