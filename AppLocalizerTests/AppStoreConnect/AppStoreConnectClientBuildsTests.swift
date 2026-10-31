//
//  AppStoreConnectClientBuildsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Whether the build attached to a version has an Apple Watch app: App
/// Store Connect lists the icons it extracted from the binary, and a watch
/// app brings a `WATCH_APP_STORE` one.
@MainActor
@Suite("App Store Connect · the build's watch app")
struct AppStoreConnectClientBuildsTests {
    private static let build = CannedHTTPResponse(body: #"{"data":{"type":"builds","id":"b42","attributes":{"version":"42"}}}"#)
    private static let noBuild = CannedHTTPResponse(body: #"{"data":null}"#)

    private static func icons(_ types: [String]) -> CannedHTTPResponse {
        let data = types.enumerated().map { index, type in
            #"{"type":"buildIcons","id":"icon\#(index)","attributes":{"iconType":"\#(type)"}}"#
        }
        return CannedHTTPResponse(body: #"{"data":[\#(data.joined(separator: ","))]}"#)
    }

    private func client(_ transport: FakeHTTPTransport) -> AppStoreConnectClient {
        AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
    }

    @Test func theBuildsIconsAreRead() async throws {
        let transport = FakeHTTPTransport([Self.icons(["APP_STORE", "WATCH_APP_STORE"])])
        let types = try await client(transport).buildIconTypes(buildID: "b42")
        #expect(types == ["APP_STORE", "WATCH_APP_STORE"])

        let request = try #require(transport.requests.first)
        #expect(request.url?.path() == "/v1/builds/b42/icons")
        let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        #expect(Set(query.map { "\($0.name)=\($0.value ?? "")" }) == ["fields[buildIcons]=iconType", "limit=50"])
    }

    @Test func aBuildWithAWatchIconHasAWatchApp() async throws {
        let transport = FakeHTTPTransport([Self.build, Self.icons(["APP_STORE", "WATCH_APP_STORE"])])
        #expect(try await client(transport).versionHasWatchApp(versionID: "v14"))
        #expect(transport.requests.map { $0.url?.path() } == ["/v1/appStoreVersions/v14/build", "/v1/builds/b42/icons"])
    }

    @Test func aBuildWithoutOneDoesnt() async throws {
        let transport = FakeHTTPTransport([Self.build, Self.icons(["APP_STORE", "MESSAGES_APP_STORE"])])
        #expect(try await !client(transport).versionHasWatchApp(versionID: "v14"))
    }

    @Test func withNoBuildAttachedNothingMoreIsAsked() async throws {
        let transport = FakeHTTPTransport([Self.noBuild])
        #expect(try await !client(transport).versionHasWatchApp(versionID: "v14"))
        #expect(transport.requests.count == 1)
    }

    @Test func theLiveServicesAskAboutTheVersionsBuild() async throws {
        let transport = FakeHTTPTransport([Self.build, Self.icons(["WATCH_APP_STORE"])])
        let services = LiveStorePageServices(client: client(transport), machineTranslations: InMemoryMachineTranslationStore())
        let app = StoreApp(id: "1", name: "Lumen", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")
        #expect(try await services.hasWatchApp(for: app, versionID: "v14"))
    }
}
