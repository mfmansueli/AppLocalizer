//
//  AutopilotTestFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
@testable import AppLocalizer

/// Centers, plans, runs and captures for the Autopilot tests: Lumen
/// Journal's sample screenshots (`DebugScreenshotsServices`), a fixed
/// clock and IDs counted from `id-1`.
@MainActor
enum AutopilotTestFixtures {
    static let appID = DebugFixtures.AppID.lumen
    static let client = "Claude Code"
    nonisolated static let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

    /// Lumen Journal with its moon icon, so starters take its colors.
    static let app = StoreApp(
        id: appID, name: "Lumen Journal", bundleID: "com.northpier.lumen", sku: "LUMEN-01", primaryLocale: "en-US",
        icon: .symbol("moon.fill", top: 0x7C86FF, bottom: 0x3A2FB8)
    )

    /// A center that keeps nothing on disk, with a fixed clock and IDs
    /// `id-1`, `id-2`, ….
    static func center(holdsStages: Bool = false) -> AutopilotCenter {
        let center = AutopilotCenter()
        var next = 0
        center.now = { now }
        center.makeID = {
            next += 1
            return "id-\(next)"
        }
        center.holdsStages = holdsStages
        return center
    }

    /// The sample screenshot services, holding `center`.
    static func services(_ center: AutopilotCenter) -> DebugScreenshotsServices {
        let services = DebugScreenshotsServices()
        services.autopilot = center
        return services
    }

    static func context(_ services: any ScreenshotsServices) -> AutopilotContext {
        AutopilotContext(app: app, services: services, primaryLocale: .englishUS)
    }

    // MARK: - Plans

    /// Two screens on iPhone and iPad in English and German: eight
    /// captures.
    static var smallPlan: AutopilotPlan {
        AutopilotPlan(
            screens: [
                AutopilotScreen(name: "Today", steps: "launch → Today", caption: "Write a little every day"),
                AutopilotScreen(name: "Week", steps: "tab “Week” → scroll to top", caption: "Your whole week on one calm page"),
            ],
            displayTypes: [.iPhone, .iPad],
            localeCodes: ["en-US", "de-DE"],
            primaryLocale: "en-US"
        )
    }

    /// One screen on iPhone in English: a single capture.
    static func singlePlan(stopsToPick: Bool = true, stopsToChoose: Bool = true) -> AutopilotPlan {
        var plan = AutopilotPlan(
            screens: [AutopilotScreen(name: "Today", steps: "launch → Today", caption: "Write a little every day")],
            displayTypes: [.iPhone],
            localeCodes: ["en-US"],
            primaryLocale: "en-US"
        )
        plan.stopsToPick = stopsToPick
        plan.stopsToChoose = stopsToChoose
        return plan
    }

    // MARK: - Runs

    /// A run of `plan` at `stage`, as `run-1` with upload token `token-1`.
    static func run(_ stage: AutopilotStage, plan: AutopilotPlan = smallPlan, design: DesignProjectKind = .none) -> AutopilotRun {
        var run = AutopilotRun(
            id: "run-1", appID: appID, versionString: "1.4", stage: stage, plan: plan, designKind: design,
            designName: nil, client: stage == .plan || stage == .waiting ? nil : client, uploadToken: "token-1", createdAt: now
        )
        if stage != .plan { run.startedAt = now }
        return run
    }

    static func target(_ screenID: String, _ display: ScreenshotDisplayType = .iPhone, _ locale: String = "en-US") -> AutopilotCaptureTarget {
        AutopilotCaptureTarget(screenID: screenID, displayType: display, locale: locale)
    }

    /// A capture of `target`; on iPhone Duo, `plan` sizes it for its pose
    /// (the cover display for a closed screen).
    static func capture(
        _ target: AutopilotCaptureTarget, in plan: AutopilotPlan? = nil, attempt: Int = 1, score: Double = 0.9, second: Int = 0
    ) -> AutopilotCapture {
        let name = "\(target.screenID)-\(target.displayType.mcpValue)-\(target.locale)-\(attempt)"
        let size = plan?.duoPose(for: target)?.portraitPixelSize ?? target.displayType.portraitPixelSize
        return AutopilotCapture(
            id: "cap-\(name)", target: target, attempt: attempt, score: score, notes: "", captureID: "png-\(name)",
            pixelSize: size, receivedAt: now.addingTimeInterval(Double(second))
        )
    }

    /// One capture of each of the plan's targets, but `except`.
    static func captureAll(_ run: inout AutopilotRun, except: Set<AutopilotCaptureTarget> = []) {
        for (index, target) in run.plan.targets.enumerated() where !except.contains(target) {
            run.captures.append(capture(target, in: run.plan, second: index))
        }
    }

    static func problem(
        _ target: AutopilotCaptureTarget, id: String = "pr-1", fix: String? = "xcrun simctl privacy booted grant photos com.northpier.lumen",
        refused: String? = nil, resolution: AutopilotProblemResolution? = nil
    ) -> AutopilotProblem {
        AutopilotProblem(
            id: id, target: target, what: "The photo picker asked for access and covered the entry.", proposedFix: fix,
            refusedCommand: refused, resolution: resolution, reportedAt: now
        )
    }

    /// A file of the device's portrait size, or its landscape one.
    static func file(_ display: ScreenshotDisplayType, landscape: Bool = false, id: String = "png-1") -> CaptureFile {
        let size = display.portraitPixelSize
        return CaptureFile(id: id, pixelSize: landscape ? size.rotated : size)
    }

    // MARK: - Images

    /// A flat PNG of `width` × `height`.
    static func png(width: Int = 12, height: Int = 26) -> Data {
        guard let image = FakeScreenshotsServices.flatImage(width: width, height: height) else { return Data() }
        return ScreenshotPNG.data(image) ?? Data()
    }

    /// A `size` × `size` image whose rows above `split` are `top` and the
    /// rest `bottom`, both opaque sRGB colors.
    static func twoBandImage(size: Int = 24, split: Int = 12, top: CGColor, bottom: CGColor) -> CGImage? {
        guard let context = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        // Core Graphics counts rows from the bottom.
        context.setFillColor(bottom)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size - split))
        context.setFillColor(top)
        context.fill(CGRect(x: 0, y: size - split, width: size, height: split))
        return context.makeImage()
    }
}
#endif
