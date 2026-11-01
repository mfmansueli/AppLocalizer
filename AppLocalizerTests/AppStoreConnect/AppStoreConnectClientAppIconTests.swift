//
//  AppStoreConnectClientAppIconTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// An app's icon: App Store Connect keeps the icon it took from each
/// build's binary, at a URL template that names the size and format.
@MainActor
@Suite("App Store Connect · the app's icon")
struct AppStoreConnectClientAppIconTests {
    private static let template = "https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/10/5b/AppIcon60x60@2x.png/{w}x{h}bb.{f}"

    /// One build per entry: its icon's template, `""` for a build whose
    /// token is null, nil for one without attributes.
    private static func builds(_ templates: [String?]) -> CannedHTTPResponse {
        let data = templates.enumerated().map { index, template -> String in
            let attributes = switch template {
            case nil: ""
            case ""?: #","attributes":{"iconAssetToken":null}"#
            case let template?: #","attributes":{"iconAssetToken":{"templateUrl":"\#(template)","width":120,"height":120}}"#
            }
            return #"{"type":"builds","id":"b\#(index)"\#(attributes)}"#
        }
        return CannedHTTPResponse(body: #"{"data":[\#(data.joined(separator: ","))]}"#)
    }

    private func client(_ transport: FakeHTTPTransport) -> AppStoreConnectClient {
        AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
    }

    @Test func theLatestBuildsIconIsServedAsAPNG() async throws {
        let transport = FakeHTTPTransport([Self.builds([Self.template])])
        let url = try await client(transport).appIconURL(appID: "6825428345")
        #expect(url?.absoluteString == "https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/10/5b/AppIcon60x60@2x.png/256x256bb.png")

        let request = try #require(transport.requests.first)
        #expect(request.url?.path() == "/v1/builds")
        let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        #expect(Set(query.map { "\($0.name)=\($0.value ?? "")" }) == [
            "filter[app]=6825428345", "sort=-uploadedDate", "fields[builds]=iconAssetToken", "limit=5",
        ])
    }

    @Test func buildsWithoutAnIconAreSkipped() async throws {
        let transport = FakeHTTPTransport([Self.builds([nil, "", Self.template])])
        let url = try await client(transport).appIconURL(appID: "1", side: 128)
        #expect(url?.lastPathComponent == "128x128bb.png")
    }

    @Test func anAppWithoutBuildsHasNoIcon() async throws {
        let transport = FakeHTTPTransport([Self.builds([])])
        #expect(try await client(transport).appIconURL(appID: "1") == nil)
    }

    @Test func aTemplateWithoutASizeIsntAnIcon() {
        #expect(BuildIconAssetAttributes.IconAsset(templateUrl: "https://example.com/icon.png").url(side: 256) == nil)
        #expect(BuildIconAssetAttributes.IconAsset(templateUrl: nil).url(side: 256) == nil)
    }

    @Test func theLiveServicesAskTheClient() async throws {
        let transport = FakeHTTPTransport([Self.builds([Self.template])])
        let url = try await LiveAppListServices(client: client(transport)).iconURL(appID: "1")
        #expect(url?.lastPathComponent == "256x256bb.png")
    }
}
