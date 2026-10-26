//
//  StorePageCannedResponses.swift
//  AppLocalizerTests
//

import Foundation

/// App Store Connect's answers for the Store Page's reads, shaped like the
/// real JSON:API pages (trimmed to the attributes the app asks for).
enum StorePageCannedResponses {
    static func page(_ resources: [String], next: String? = nil, included: [String]? = nil) -> CannedHTTPResponse {
        var body = #"{"data":[\#(resources.joined(separator: ","))]"#
        if let included { body += #","included":[\#(included.joined(separator: ","))]"# }
        if let next { body += #","links":{"self":"https://api.appstoreconnect.apple.com/v1/x","next":"\#(next)"}"# }
        return CannedHTTPResponse(body: body + "}")
    }

    static func version(_ id: String, _ versionString: String, state: String, created: String) -> String {
        #"{"type":"appStoreVersions","id":"\#(id)","attributes":{"versionString":"\#(versionString)","platform":"IOS","appVersionState":"\#(state)","createdDate":"\#(created)"}}"#
    }

    static func appInfo(_ id: String, state: String) -> String {
        #"{"type":"appInfos","id":"\#(id)","attributes":{"state":"\#(state)"}}"#
    }

    static func appInfoLocalization(_ id: String, locale: String, name: String, subtitle: String? = nil) -> String {
        let subtitle = subtitle.map { #","subtitle":"\#($0)""# } ?? ""
        return #"{"type":"appInfoLocalizations","id":"\#(id)","attributes":{"locale":"\#(locale)","name":"\#(name)"\#(subtitle),"privacyPolicyUrl":null}}"#
    }

    static func versionLocalization(_ id: String, locale: String, description: String, keywords: String = "") -> String {
        #"{"type":"appStoreVersionLocalizations","id":"\#(id)","attributes":{"locale":"\#(locale)","description":"\#(description)","keywords":"\#(keywords)","whatsNew":null}}"#
    }

    static func screenshotSet(_ id: String, displayType: String, screenshots: Int) -> String {
        let data = (0..<screenshots).map { #"{"type":"appScreenshots","id":"\#(id)-\#($0)"}"# }.joined(separator: ",")
        return #"{"type":"appScreenshotSets","id":"\#(id)","attributes":{"screenshotDisplayType":"\#(displayType)"},"relationships":{"appScreenshots":{"data":[\#(data)]}}}"#
    }

    static func named(_ type: String, _ id: String, _ attributes: String) -> String {
        #"{"type":"\#(type)","id":"\#(id)","attributes":{\#(attributes)}}"#
    }

    /// Lumen's versions (1.4 editable, 1.3 live, 1.2 replaced), app infos,
    /// and English and German texts, in the loader's order.
    static var lumen: [CannedHTTPResponse] {
        [
            page([
                version("v13", "1.3", state: "READY_FOR_DISTRIBUTION", created: "2026-08-01T09:00:00-07:00"),
                version("v14", "1.4", state: "PREPARE_FOR_SUBMISSION", created: "2026-10-01T09:00:00-07:00"),
                version("v12", "1.2", state: "REPLACED_WITH_NEW_VERSION", created: "2026-05-01T09:00:00-07:00"),
            ]),
            page([appInfo("info-live", state: "READY_FOR_DISTRIBUTION"), appInfo("info-next", state: "PREPARE_FOR_SUBMISSION")]),
            page([
                appInfoLocalization("il-en", locale: "en-US", name: "Lumen: Daily Journal", subtitle: "Private notes, gentle prompts"),
                appInfoLocalization("il-de", locale: "de-DE", name: "Lumen: Tagebuch"),
                appInfoLocalization("il-xx", locale: "xx-YY", name: "Unknown"),
            ]),
            page([
                versionLocalization("vl-en", locale: "en-US", description: "Lumen is a quiet place.", keywords: "diary,mood"),
                versionLocalization("vl-de", locale: "de-DE", description: "Lumen ist ein ruhiger Ort."),
            ]),
        ]
    }
}
