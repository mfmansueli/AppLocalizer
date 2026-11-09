//
//  StorePageVersionPlatformTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// An app's iOS and macOS versions can both be "1.0": the picker says
/// which is which, and each platform has its own first version.
@MainActor
@Suite("StorePageVersion · platforms")
struct StorePageVersionPlatformTests {
    private static func version(_ string: String, platform: String?) -> StorePageVersion {
        StorePageVersion(id: "\(platform ?? "none")-\(string)", listingVersion: ListingVersion(string, state: .prepareForSubmission), platform: platform)
    }

    private static let iOS = version("1.0", platform: "IOS")
    private static let mac = version("1.0", platform: "MAC_OS")

    @Test func thePickerNamesThePlatformOnlyWhenThereAreSeveral() {
        #expect(Self.iOS.pickerTitle(among: [Self.iOS]) == Self.iOS.listingVersion.pickerTitle)
        #expect(Self.iOS.pickerTitle(among: [Self.iOS, Self.mac]) == "\(Self.iOS.listingVersion.pickerTitle) · iOS")
        #expect(Self.mac.pickerTitle(among: [Self.iOS, Self.mac]) == "\(Self.mac.listingVersion.pickerTitle) · macOS")
        #expect(Self.mac.title(among: [Self.iOS, Self.mac]) == "\(Self.mac.listingVersion.title) · macOS")
        #expect(Self.mac.title(among: [Self.mac]) == Self.mac.listingVersion.title)
    }

    @Test func aPlatformWithoutANameStaysPlain() {
        let other = Self.version("1.0", platform: "WATCH_OS")
        #expect(other.platformTitle == nil)
        #expect(other.pickerTitle(among: [Self.iOS, other]) == other.listingVersion.pickerTitle)
    }

    @Test func onlyOtherPlatformsReachTheReviewHeading() {
        #expect(Self.iOS.otherPlatformTitle == nil)
        #expect(Self.mac.otherPlatformTitle == "macOS")
        #expect(Self.version("1.0", platform: "VISION_OS").otherPlatformTitle == "visionOS")
    }

    @Test func theReviewHeadingSaysWhichVersion() {
        var builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        #expect(builder.group(at: .version) == "Store Page · Version 2.0")
        builder.platformTitle = "macOS"
        #expect(builder.group(at: .version) == "Store Page · macOS Version 2.0")
        #expect(builder.group(at: .app) == "Store Page · App information")
    }

    @Test func aFirstVersionIsCountedPerPlatform() {
        let platforms: [String?] = ["IOS", "IOS", "MAC_OS"]
        #expect(StorePageVersion.isOnlyVersion(of: "MAC_OS", among: platforms))
        #expect(!StorePageVersion.isOnlyVersion(of: "IOS", among: platforms))
    }
}
#endif
