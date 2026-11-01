//
//  ScreenshotsCannedResponses.swift
//  AppLocalizerTests
//

import Foundation

/// App Store Connect's screenshot and App Preview set pages, shaped like
/// the real JSON:API (trimmed to the fields the app asks for).
enum ScreenshotsCannedResponses {
    static func page(_ data: [String], included: [String] = [], next: String? = nil) -> CannedHTTPResponse {
        var body = #"{"data":[\#(data.joined(separator: ","))],"included":[\#(included.joined(separator: ","))]"#
        if let next { body += #","links":{"self":"https://api.appstoreconnect.apple.com/v1/x","next":"\#(next)"}"# }
        return CannedHTTPResponse(body: body + "}")
    }

    static func screenshotSet(_ id: String, displayType: String, screenshots: [String]) -> String {
        let data = screenshots.map { #"{"type":"appScreenshots","id":"\#($0)"}"# }.joined(separator: ",")
        return #"{"type":"appScreenshotSets","id":"\#(id)","attributes":{"screenshotDisplayType":"\#(displayType)"},"#
            + #""relationships":{"appScreenshots":{"data":[\#(data)]}}}"#
    }

    static func screenshot(_ id: String, fileName: String, checksum: String) -> String {
        #"{"type":"appScreenshots","id":"\#(id)","attributes":{"fileName":"\#(fileName)","sourceFileChecksum":"\#(checksum)","#
            + #""imageAsset":{"templateUrl":"https://example.invalid/\#(id)/{w}x{h}bb.{f}","width":1320,"height":2868}}}"#
    }

    /// A screenshot App Store Connect has no image for yet: its delivery
    /// state but no `imageAsset`.
    static func screenshot(_ id: String, deliveryState: String) -> String {
        #"{"type":"appScreenshots","id":"\#(id)","attributes":{"fileName":"\#(id).png","assetDeliveryState":{"state":"\#(deliveryState)"}}}"#
    }

    static func previewSet(_ id: String, previewType: String, previews: [String]) -> String {
        let data = previews.map { #"{"type":"appPreviews","id":"\#($0)"}"# }.joined(separator: ",")
        return #"{"type":"appPreviewSets","id":"\#(id)","attributes":{"previewType":"\#(previewType)"},"#
            + #""relationships":{"appPreviews":{"data":[\#(data)]}}}"#
    }

    static func preview(_ id: String, timeCode: String) -> String {
        #"{"type":"appPreviews","id":"\#(id)","attributes":{"fileName":"preview.mov","previewFrameTimeCode":"\#(timeCode)"}}"#
    }
}
