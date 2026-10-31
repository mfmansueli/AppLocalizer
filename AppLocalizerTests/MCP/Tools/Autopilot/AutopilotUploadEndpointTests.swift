//
//  AutopilotUploadEndpointTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `POST /autopilot/<token>`: the assistant uploads each capture's PNG,
/// then names the returned upload in `report_capture`. The run's token is
/// the link's only secret.
@MainActor
@Suite("Autopilot upload link")
struct AutopilotUploadEndpointTests {
    private let controller = MCPTestFixtures.controller()
    private let fixtures: MCPAutopilotFixtures

    init() {
        fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture))
        controller.workspace = fixtures.workspace
    }

    private func send(
        _ body: Data, token: String = "debug-token", method: String = "POST", headers: [String: String] = [:]
    ) async throws -> HTTPResponse {
        let allHeaders = ["Host": "127.0.0.1:47321", "Content-Type": "image/png"].merging(headers) { $1 }
        let request = HTTPRequest(method: method, target: MCPEndpoint.autopilotPath + token, headers: allHeaders, body: body)
        return try #require(await controller.handle(request).response)
    }

    @Test(arguments: ["POST", "PUT"])
    func aPNGIsKeptForReportCapture(method: String) async throws {
        let png = AutopilotTestFixtures.png(width: 12, height: 26)
        let response = try await send(png, method: method)

        #expect(response.status == 200)
        #expect(try MCPTestFixtures.json(response) == ["upload": "up-id-1", "checksum": .string(ScreenshotPNG.checksum(png)), "pixelSize": "12 × 26"])
        let upload = try #require(fixtures.center.uploads["up-id-1"])
        #expect(upload.runID == "run-debug")
        #expect(upload.appID == MCPAutopilotFixtures.appID)
        #expect(upload.file == CaptureFile(id: ScreenshotPNG.checksum(png), pixelSize: PixelSize(width: 12, height: 26)))
        #expect(upload.receivedAt == AutopilotTestFixtures.now)
    }

    @Test func anUnknownOrFinishedRunsLinkIsRefused() async throws {
        let unknown = try await send(AutopilotTestFixtures.png(), token: "not-the-token")
        #expect(unknown.status == 404)
        #expect(try MCPTestFixtures.json(unknown) == ["error": "Unknown or finished run; call get_capture_plan for the current upload link."])
        #expect(try await send(AutopilotTestFixtures.png(), token: "").status == 404)

        fixtures.center.install(StudioDebugRuns.run(.ready))
        #expect(try await send(AutopilotTestFixtures.png()).status == 404)
        #expect(fixtures.center.uploads.isEmpty)
    }

    @Test func onlyAPNGIsTaken() async throws {
        let text = try await send(Data("hello".utf8))
        #expect(text.status == 422)
        #expect(try MCPTestFixtures.json(text) == ["error": "That isn’t a PNG. Send the screenshot file’s bytes."])

        let empty = try await send(Data())
        #expect(empty.status == 400)
        #expect(try MCPTestFixtures.json(empty) == ["error": "The body is empty: send the PNG's bytes with curl --data-binary @file.png."])
        #expect(fixtures.center.uploads.isEmpty)
    }

    @Test func onlyUploadsFromThisMacAreTaken() async throws {
        let png = AutopilotTestFixtures.png()
        #expect(try await send(png, headers: ["Origin": "https://evil.example"]).status == 403)
        #expect(try await send(png, headers: ["Host": "evil.example:47321"]).status == 403)
        let read = try await send(Data(), method: "GET")
        #expect(read.status == 405)
        #expect(read.headers["Allow"] == "POST, PUT")
        #expect(fixtures.center.uploads.isEmpty)
    }

    @Test func withoutAnAccountOpenThereIsNoRun() async throws {
        controller.workspace = nil
        #expect(try await send(AutopilotTestFixtures.png()).status == 404)
    }

    @Test func theLinkIsTheRunsTokenOnTheServersPort() {
        #expect(MCPEndpoint.autopilotPath == "/autopilot/")
        #expect(MCPEndpoint.autopilotUploadURL(port: 47321, token: "abc123") == "http://127.0.0.1:47321/autopilot/abc123")
        #expect(MCPEndpoint.autopilotUploadURL(port: 4000, token: "t") == "http://127.0.0.1:4000/autopilot/t")
    }
}
#endif
