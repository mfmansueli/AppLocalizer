//
//  TemplateEditorViewModel+Inspector.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// The inspector's edits that take more than one field, and its texts.
extension TemplateEditorViewModel {
    // MARK: - Canvas

    /// The canvas's orientation, as the canvas shows it: iPhone Duo without
    /// one of its own lies the way the capture on it does.
    var orientation: ScreenshotOrientation {
        guard let canvas = template?.canvas else { return displayType.isTablet || displayType.isAlwaysLandscape ? .landscape : .portrait }
        let document = screenshots.document
        let capture = document?.captures.capture(locale: localeCode, displayType: displayType, slot: slot, primary: document?.scope.primary ?? localeCode)
        return canvas.following(capture?.capture.pixelSize, on: displayType).orientation(for: displayType)
    }

    func setOrientation(_ orientation: ScreenshotOrientation) {
        set(TemplateCanvas.path(for: displayType), to: .string(orientation.rawValue))
    }

    /// "1320 × 2868 px · PNG · APP_IPHONE_67".
    var outputText: String {
        let size = ScreenshotCanvas(display: displayType, orientation: orientation).pixelSize
        return "\(size.title) px · PNG · \(displayType.apiValue)"
    }

    // MARK: - Background

    /// Switching the kind starts from its usual colors: one stop for solid,
    /// two at 168° for a gradient, the panorama starter's five. A slot with
    /// its own background switches that one, between solid and gradient.
    func setBackgroundKind(_ kind: TemplateBackground.Kind) {
        if hasOwnBackground {
            guard kind == .solid || kind == .linear else { return }
            editOwnBackground { background in
                guard background.kind != kind else { return }
                background.stops = kind == .solid ? [background.stops.last ?? "#17143D"] : Self.gradientStops(from: background.stops)
                background.angle = kind == .linear ? background.angle ?? 168 : nil
                background.kind = kind
            }
            return
        }
        guard let template, template.background.kind != kind else { return }
        let stops: [String] = switch kind {
        case .solid: [template.background.stops.last ?? "#17143D"]
        case .linear: Self.gradientStops(from: template.background.stops)
        case .panorama, .image: ScreenshotTemplate.starter(.panorama, id: "", title: "").background.stops
        }
        var operations: [TemplateOperation] = [
            .replace("bg.kind", with: .string(kind.rawValue)), .replace("bg.stops", with: .array(stops.map(JSONValue.string))),
        ]
        if kind == .linear, template.background.angle == nil { operations.append(.replace("bg.angle", with: .double(168))) }
        apply(operations)
    }

    func setBackgroundStop(_ index: Int, to color: String) {
        guard var stops = effectiveBackground?.stops, stops.indices.contains(index) else { return }
        stops[index] = color
        if hasOwnBackground {
            editOwnBackground { $0.stops = stops }
        } else {
            set("bg.stops", to: .array(stops.map(JSONValue.string)))
        }
    }

    func setBackgroundAngle(_ angle: Double) {
        if hasOwnBackground {
            editOwnBackground { $0.angle = angle }
        } else {
            set("bg.angle", to: .double(angle))
        }
    }

    /// A gradient keeps up to three of the current colors, or starts from
    /// the starter's indigo.
    private static func gradientStops(from stops: [String]) -> [String] {
        stops.count >= 2 ? Array(stops.prefix(3)) : ["#7A80FF", "#3A2FB8"]
    }

    // MARK: - Device

    /// The device finishes the inspector offers.
    static let deviceFinishes: [(color: String, title: String)] = [
        ("#141416", String(localized: "Black")), ("#C9CBD1", String(localized: "Silver")), ("#F4F4F6", String(localized: "White")),
    ]

    /// "iPhone 17 Pro Max", "iPad Pro 13″ · landscape", "iPhone Duo · inner
    /// display", "MacBook Pro" (always landscape).
    var frameName: String {
        if displayType == .mac { return String(localized: "MacBook Pro") }
        let name = switch displayType {
        case .iPad: String(localized: "iPad Pro 13″")
        case .iPhoneDuo: String(localized: "iPhone Duo · inner display")
        default: displayType.deviceName
        }
        return orientation == .landscape ? String(localized: "\(name) · landscape") : name
    }

    /// A band caption has no device: the capture fills the canvas.
    var showsDevice: Bool {
        guard let template else { return false }
        return template.device.show && template.caption.placement != .band
    }

    // MARK: - Caption

    /// The headline and display font together, as the design's picker
    /// sets them.
    func setDisplayFont(_ name: String) {
        apply([.replace("fonts.display", with: .string(name)), .replace("caption.headline.font", with: .string(name))])
    }

    /// "Northpier Display · uploaded", "Anton · bundled".
    func fontTitle(_ name: String) -> String {
        if screenshots.fonts.isUploaded(name) { return String(localized: "\(name) · uploaded") }
        return screenshots.fonts.isBundled(name) ? String(localized: "\(name) · bundled") : name
    }

    /// The headline picker's fonts, with the current one even if it isn't
    /// installed.
    var displayFontOptions: [String] {
        let options = screenshots.fonts.displayFonts
        guard let current = template?.caption.headline.font, !options.contains(current) else { return options }
        return options + [current]
    }

    /// Lowering the size under the smallest size takes the smallest size
    /// with it; the smallest size can't pass the size.
    func setHeadlineSize(_ size: Double) {
        guard let template else { return }
        var operations: [TemplateOperation] = [.replace("caption.headline.size", with: .double(size))]
        if template.caption.headline.min > size { operations.append(.replace("caption.headline.min", with: .double(size))) }
        apply(operations)
    }

    // MARK: - Fit

    /// "Caption box 1122 × 259 px on iPhone 6.9″ portrait, reserved at the
    /// maximum lines so the device never moves between locales.", or sized
    /// to each language's lines in a tight box.
    var captionBoxText: String {
        guard let box = canvas?.layout.captionBox else { return "" }
        let size = "\(Int(box.width.rounded())) × \(Int(box.height.rounded()))"
        if template?.caption.headline.isTight == true {
            return String(
                localized: "Caption box \(size) px on \(displayType.title) \(orientation.title.lowercased()), sized to each language’s lines: the device moves down when a language needs one more line."
            )
        }
        return String(localized: "Caption box \(size) px on \(displayType.title) \(orientation.title.lowercased()), reserved at the maximum lines so the device never moves between locales.")
    }

    // MARK: - Fonts by script

    /// "SF Pro Display draws Latin, Cyrillic, Greek. Every other script
    /// needs a fallback."
    var displayCoverageText: String {
        guard let template else { return "" }
        let drawn = ScreenshotScript.allCases.filter { fontCoverage.covers(template.fonts.display, $0, in: screenshots.fonts) }
        let list = drawn.map(\.title).formatted(.list(type: .and))
        return drawn.isEmpty
            ? String(localized: "\(template.fonts.display) isn’t installed on this Mac, so every script needs a fallback.")
            : String(localized: "\(template.fonts.display) draws \(list). Every other script needs a fallback.")
    }

    var fontRows: [FontScriptRow] {
        guard let template, let document = screenshots.document else { return [] }
        let fonts = screenshots.fonts
        let locales = document.scope.orderedLocales(in: screenshots.locales.map(\.code)).compactMap(screenshots.locale(code:))
        return ScreenshotScript.allCases.map { script in
            FontScriptRow(
                script: script, displayFont: template.fonts.display,
                isDrawnByDisplayFont: fontCoverage.covers(template.fonts.display, script, in: fonts),
                fallback: template.fonts.fallback(for: script), options: fontCoverage.fonts(drawing: script, in: fonts),
                localeCount: locales.count { ScreenshotScript(locale: $0) == script }
            )
        }
    }

    func setFallback(_ font: String?, for script: ScreenshotScript) {
        set("fonts.fallback.\(script.rawValue)", to: font.map(JSONValue.string) ?? .null)
    }

    // MARK: - Uploaded fonts

    /// Upload Font…: registers the file and makes it the display font.
    func uploadFont(from url: URL) async {
        do {
            let family = try await screenshots.uploadFont(from: url)
            uploadError = nil
            setDisplayFont(family)
        } catch {
            uploadError = error.localizedDescription
        }
    }
}
