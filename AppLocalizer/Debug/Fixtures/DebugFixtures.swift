//
//  DebugFixtures.swift
//  AppLocalizer
//

#if DEBUG
import CryptoKit
import Foundation

/// Canned data for DEBUG scenes: the design's sample account, Northpier
/// Studio, and its apps. Illustrative only.
enum DebugFixtures {
    static let issuerID = "69a6de7f-3c2e-47e3-e053-5b8c7c11a4d1"
    static let keyID = "2X9R4HXF34"

    /// A freshly generated P-256 key in the same PKCS#8 PEM format as a
    /// downloaded `.p8`, named the way App Store Connect names them.
    static var privateKey: ImportedPrivateKey {
        ImportedPrivateKey(fileName: "AuthKey_\(keyID).p8", pem: P256.Signing.PrivateKey().pemRepresentation)
    }

    // MARK: - Accounts

    static let northpier = TeamAccount(id: keyID, name: "Northpier Studio", role: String(localized: "Admin"))
    static let brightline = TeamAccount(id: "Q7MZ3K8PLA", name: "Brightline Apps", role: String(localized: "App Manager"))
    static let accounts = [northpier, brightline]

    // MARK: - Apps

    enum AppID {
        static let lumen = "6450000001"
        static let habitat = "6450000002"
        static let tempo = "6450000003"
        static let fieldnote = "6450000004"
        static let parcel = "6450000005"
        static let quiet = "6450000006"
    }

    /// Sorted by name, as `GET /v1/apps?sort=name` returns them.
    static let apps: [StoreApp] = [
        StoreApp(id: AppID.fieldnote, name: "Fieldnote Scanner", bundleID: "dev.northpier.fieldnote", sku: "FNOTE", primaryLocale: "en-US"),
        StoreApp(
            id: AppID.habitat,
            name: "Habitat — Plant Care",
            bundleID: "dev.northpier.habitat",
            sku: "HABITAT",
            primaryLocale: "en-US",
            icon: .symbol("leaf.fill", top: 0x63D891, bottom: 0x1E8C4E)
        ),
        StoreApp(
            id: AppID.lumen,
            name: "Lumen Journal",
            bundleID: "dev.northpier.lumen",
            sku: "LUMEN-01",
            primaryLocale: "en-US",
            icon: .symbol("moon.fill", top: 0x7C86FF, bottom: 0x3A2FB8)
        ),
        StoreApp(id: AppID.parcel, name: "Parcel Pal", bundleID: "dev.northpier.parcel", sku: "PARCEL", primaryLocale: "en-US"),
        StoreApp(id: AppID.quiet, name: "Quiet Timer", bundleID: "dev.northpier.quiet", sku: "QUIET", primaryLocale: "en-US"),
        StoreApp(
            id: AppID.tempo,
            name: "Tempo Metronome",
            bundleID: "dev.northpier.tempo",
            sku: "TEMPO-2",
            primaryLocale: "en-US",
            icon: .symbol("metronome.fill", top: 0xFFB65E, bottom: 0xE0602A)
        ),
    ]

    static var lumen: StoreApp { apps.first { $0.id == AppID.lumen }! }
}
#endif
