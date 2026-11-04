//
//  ScreenshotStudioModel+ArtworkChoice.swift
//  AppLocalizer
//

import AppKit
import Foundation
import UniformTypeIdentifiers

/// The plan's iPhone Duo row (what its screenshots show) and Header and
/// search row: a still image or a motion loop, what the search artwork
/// shows, and the expected result in words and references.
extension ScreenshotStudioModel {
    // MARK: - iPhone Duo

    func setDuoScreens(_ screens: AutopilotDuoScreens) {
        updatePlan { $0.runChoice.duoScreens = screens }
    }

    func setDuoBoth(_ both: AutopilotDuoBoth) {
        updatePlan { $0.runChoice.duoBoth = both }
    }

    // MARK: - Header and search

    func setArtworkMotion(_ motion: AutopilotArtworkMotion) {
        updatePlan { $0.alsoMakes.setMotion(motion) }
    }

    func setArtworkSize(_ size: AutopilotArtworkSize) {
        updatePlan { $0.alsoMakes.setArtworkSize(size) }
    }

    func setArtworkShows(_ shows: AutopilotArtworkShow) {
        updatePlan { $0.alsoMakes.artworkShows = shows }
    }

    /// Under Still or motion: what the loop moves, why 16:9 can't move, or
    /// what a still is.
    static func artworkMotionNote(_ extras: AutopilotExtras) -> String {
        if extras.makesMotion {
            // The header alone shows no phone or screen to float.
            let float = switch extras.artworkSize.searchKind == nil ? .scene : extras.artworkShows {
            case .scene: ""
            case .ui: String(localized: ", a gentle float of the screen")
            case .phone: String(localized: ", a gentle float of the phone")
            }
            return String(localized: "Claude Design animates its artwork into a 20-second silent loop: slow light and scene")
                + float
                + String(localized: "; the name and headline stay still. The first frame is the poster. Apple plays it on repeat, muted, at \(extras.artworkSize.shortTitle).")
        }
        if !extras.artworkSize.allowsMotion {
            return String(localized: "Apple takes motion only at 21:9 and 3:2. Choose Motion loop to switch to those sizes.")
        }
        return String(localized: "One PNG per place and language. Apple shows it as is wherever the motion version would play.")
    }

    // MARK: - Expected result

    func setArtworkText(_ text: String) {
        updatePlan { $0.alsoMakes.artworkDirection.text = text }
    }

    /// Adds a quick addition to the words.
    func addArtworkAddition(_ addition: String) {
        updatePlan { $0.alsoMakes.artworkDirection.add(addition) }
    }

    func removeArtworkReference(_ reference: AutopilotArtworkReference) {
        updatePlan { $0.alsoMakes.artworkDirection.references.removeAll { $0.fileID == reference.fileID } }
    }

    /// Add Image or Video…: images and videos the person likes, copied
    /// into the app's Extras folder and sent with the brief.
    func chooseArtworkReferences() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .movie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = String(localized: "References for the header and search artwork")
        panel.message = String(localized: "Claude Design takes the feel from them, not the content.")
        panel.prompt = String(localized: "Add")
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        Task { await addArtworkReferences(urls) }
    }

    /// Copies each file into the References folder, named by its checksum,
    /// and adds it once.
    func addArtworkReferences(_ urls: [URL]) async {
        referenceError = nil
        for url in urls {
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            let pathExtension = url.pathExtension.lowercased()
            guard AutopilotArtworkReference.allowedExtensions.contains(pathExtension) else {
                referenceError = String(localized: "“\(url.lastPathComponent)” isn’t an image or a video.")
                continue
            }
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let reference = AutopilotArtworkReference(
                    fileID: ScreenshotPNG.checksum(data) + "." + pathExtension, name: url.lastPathComponent
                )
                let copy = screenshots.services.referenceURL(reference, for: app)
                try FileManager.default.createDirectory(at: copy.deletingLastPathComponent(), withIntermediateDirectories: true)
                if !FileManager.default.fileExists(atPath: copy.path) { try data.write(to: copy, options: .atomic) }
                updatePlan { plan in
                    guard !plan.alsoMakes.artworkDirection.references.contains(where: { $0.fileID == reference.fileID }) else { return }
                    plan.alsoMakes.artworkDirection.references.append(reference)
                }
            } catch {
                referenceError = error.localizedDescription
            }
        }
    }
}
