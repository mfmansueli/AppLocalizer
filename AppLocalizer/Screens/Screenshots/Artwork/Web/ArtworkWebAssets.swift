//
//  ArtworkWebAssets.swift
//  AppLocalizer
//

import Foundation
import WebKit

/// Serves a Claude Design page the only files it can load, from
/// `al-asset:` URLs: the app's icon and captures for the language being
/// rendered (`al-asset://app/…`) and AppLocalizer's bundled and uploaded
/// fonts (`al-asset://font/…`). Everything else fails; the network is
/// blocked besides (`ArtworkWebBlocking`).
@MainActor
final class ArtworkWebAssets: NSObject, WKURLSchemeHandler {
    static let scheme = "al-asset"

    /// The icon and captures, by path ("icon.png", "capture-1.png").
    var files: [String: Data] = [:]

    /// What the page asked for that wasn't there, for the problems.
    private(set) var missing: [String] = []

    func reset(icon: Data?, captures: [Int: Data]) {
        var files: [String: Data] = [:]
        if let icon { files["icon.png"] = icon }
        for (slot, data) in captures { files["capture-\(slot + 1).png"] = data }
        self.files = files
        missing = []
    }

    func webView(_: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url else {
            task.didFailWithError(URLError(.badURL))
            return
        }
        let name = url.lastPathComponent
        let found: (data: Data, type: String)? = switch url.host() {
        case "app": files[name].map { ($0, "image/png") }
        case "font": ArtworkWebFonts.data(named: name).map { ($0, ArtworkWebFonts.mimeType(of: name)) }
        default: nil
        }
        guard let found else {
            missing.append(url.absoluteString)
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        task.didReceive(URLResponse(url: url, mimeType: found.type, expectedContentLength: found.data.count, textEncodingName: nil))
        task.didReceive(found.data)
        task.didFinish()
    }

    func webView(_: WKWebView, stop _: any WKURLSchemeTask) {}
}
