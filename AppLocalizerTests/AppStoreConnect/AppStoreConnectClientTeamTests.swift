//
//  AppStoreConnectClientTeamTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The team's name, read from its certificates: App Store Connect has no
/// endpoint that names a key's team, but every certificate's subject does
/// (`O=Northpier Studio`).
@MainActor
@Suite("App Store Connect · the team's name")
struct AppStoreConnectClientTeamTests {
    /// Self-signed, with the subject of an Apple Distribution certificate:
    /// "UID=A1B2C3D4E5, CN=Apple Distribution: Northpier Studio
    /// (A1B2C3D4E5), OU=A1B2C3D4E5, O=Northpier Studio, C=US".
    static let distribution = [
        "MIICgzCCAimgAwIBAgIUVraRCKqA+l70lu4h/Hc5Lo8vt4owCgYIKoZIzj0EAwIwgZUxGjAYBgoJkiaJk/IsZAEBDApBMUIyQzNENEU1MTowOA",
        "YDVQQDDDFBcHBsZSBEaXN0cmlidXRpb246IE5vcnRocGllciBTdHVkaW8gKEExQjJDM0Q0RTUpMRMwEQYDVQQLDApBMUIyQzNENEU1MRkwFwYD",
        "VQQKDBBOb3J0aHBpZXIgU3R1ZGlvMQswCQYDVQQGEwJVUzAgFw0yNjExMDExMjAwNDVaGA8yMTI2MTAwODEyMDA0NVowgZUxGjAYBgoJkiaJk/",
        "IsZAEBDApBMUIyQzNENEU1MTowOAYDVQQDDDFBcHBsZSBEaXN0cmlidXRpb246IE5vcnRocGllciBTdHVkaW8gKEExQjJDM0Q0RTUpMRMwEQYD",
        "VQQLDApBMUIyQzNENEU1MRkwFwYDVQQKDBBOb3J0aHBpZXIgU3R1ZGlvMQswCQYDVQQGEwJVUzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABN",
        "qz7X95WEjLTKKHl6NxVsh9WswY+PgWPhMYW+w/M6qEMfsyiBZ7KMYHtUkHig6Rc6oc7d5uyJ3p++19cvw9yUWjUzBRMB0GA1UdDgQWBBQd2KG4",
        "xosUoRAFCekLWW/958rF4jAfBgNVHSMEGDAWgBQd2KG4xosUoRAFCekLWW/958rF4jAPBgNVHRMBAf8EBTADAQH/MAoGCCqGSM49BAMCA0gAME",
        "UCIF6Mf/ZGglf3XmIxkDGQPYMQ/Qyr+H+sSb2vi/aYCu2hAiEAtz9ssGfjpzkGnVVVjzgRWwsigAg6VcBgmtzjHALbGWI=",
    ].joined()

    /// Self-signed with only "CN=Created via API": no organization.
    static let withoutOrganization = [
        "MIIBjDCCATGgAwIBAgIUSe1MinGo0LKmzKTNqxeBGhFtx5UwCgYIKoZIzj0EAwIwGjEYMBYGA1UEAwwPQ3JlYXRlZCB2aWEgQVBJMCAXDTI2MT",
        "EwMTEyMDA0NVoYDzIxMjYxMDA4MTIwMDQ1WjAaMRgwFgYDVQQDDA9DcmVhdGVkIHZpYSBBUEkwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASL",
        "QF9wvOnZHZaI3gRQ9AtutD4Mfp5qD1Oi1dcS8P6O4qAjyfco/TMAFoqlznTtkslsVeNDjECn6MxEq3fGtMoRo1MwUTAdBgNVHQ4EFgQUvmx/rs",
        "TggZh/4QyJTQVx4VN2OsMwHwYDVR0jBBgwFoAUvmx/rsTggZh/4QyJTQVx4VN2OsMwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNJADBG",
        "AiEAmvqKwcfFL0Tq+jq3WrEWtjHEf4LFpbhpUCgrM87JD9kCIQC2xRiHJzk74e1prXGzMrYKJPD7Pql1OJ1Q8kXWbA9tfA==",
    ].joined()

    private static func certificates(_ contents: [String?]) -> CannedHTTPResponse {
        let data = contents.enumerated().map { index, content in
            let attributes = content.map { #","attributes":{"certificateContent":"\#($0)"}"# } ?? ""
            return #"{"type":"certificates","id":"cert\#(index)"\#(attributes)}"#
        }
        return CannedHTTPResponse(body: #"{"data":[\#(data.joined(separator: ","))]}"#)
    }

    private func client(_ transport: FakeHTTPTransport) -> AppStoreConnectClient {
        AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
    }

    @Test func theOrganizationIsTheTeam() throws {
        let der = try #require(Data(base64Encoded: Self.distribution))
        #expect(CertificateOrganization.name(inDER: der) == "Northpier Studio")
    }

    @Test func aSubjectWithoutOneOrDataThatIsntACertificateHasNoTeam() throws {
        let der = try #require(Data(base64Encoded: Self.withoutOrganization))
        #expect(CertificateOrganization.name(inDER: der) == nil)
        #expect(CertificateOrganization.name(inDER: Data("not a certificate".utf8)) == nil)
        #expect(CertificateAttributes(certificateContent: "%%%").teamName == nil)
    }

    @Test func theTeamsNameComesFromItsCertificates() async throws {
        let transport = FakeHTTPTransport([Self.certificates([Self.distribution])])
        #expect(try await client(transport).teamName() == "Northpier Studio")

        let request = try #require(transport.requests.first)
        #expect(request.url?.path() == "/v1/certificates")
        let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        #expect(Set(query.map { "\($0.name)=\($0.value ?? "")" }) == ["fields[certificates]=certificateContent", "limit=20"])
    }

    @Test func certificatesThatDontNameItAreSkipped() async throws {
        let transport = FakeHTTPTransport([Self.certificates([nil, Self.withoutOrganization, Self.distribution])])
        #expect(try await client(transport).teamName() == "Northpier Studio")
    }

    @Test func aTeamWithoutCertificatesHasNoName() async throws {
        let transport = FakeHTTPTransport([Self.certificates([])])
        #expect(try await client(transport).teamName() == nil)
    }

    @Test func aRoleThatCantReadCertificatesIsRefused() async {
        let transport = FakeHTTPTransport([CannedHTTPResponse(statusCode: 403, body: #"{"errors":[]}"#)])
        await #expect(throws: AppStoreConnectError.self) { try await client(transport).teamName() }
    }

    @Test func theLiveServicesAskTheClient() async throws {
        let transport = FakeHTTPTransport([Self.certificates([Self.distribution])])
        #expect(try await LiveAppListServices(client: client(transport)).teamName() == "Northpier Studio")
    }
}
