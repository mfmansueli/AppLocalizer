//
//  CaptureMatcher.swift
//  AppLocalizer
//

import Foundation

/// Matches imported screenshots to locale, display type and slot (design
/// README §2 "Captures"). The locale comes from the folder or test
/// configuration (`de-DE`, or `de` when German has one App Store locale),
/// the display type from the device and pixel size, the slot from the
/// name's number or, without one, the file's order. What it can't settle
/// becomes a row that needs you: an ambiguous locale ("pt"), a capture
/// from a smaller device, a slot past the template's last. Pure.
struct CaptureMatcher {
    /// The template's slots; nil without a template, when any slot up to
    /// ten is fine.
    var slotCount: Int?

    func rows(for candidates: [CaptureCandidate]) -> [CaptureMatchRow] {
        let files = Self.numbered(candidates.map(Self.withDisplayType))
        var resolved: [(file: CaptureCandidate, locale: String)] = []
        var unresolved: [String: [CaptureCandidate]] = [:]
        for file in files {
            if let locale = StoreLocaleCatalog.resolve(file.localeCode ?? "").locale {
                resolved.append((file, locale.code))
            } else {
                unresolved[file.localeCode ?? "", default: []].append(file)
            }
        }
        // Who already fills a cell, so "Skip it" can say a capture is there.
        var fitting: [CaptureMatchRow.Placement: String] = [:]
        for (file, locale) in resolved {
            guard let display = file.displayType, let number = file.slotNumber, let size = file.pixelSize,
                  CaptureSizeRules.fits(size, in: display) else { continue }
            fitting[CaptureMatchRow.Placement(locale: locale, displayType: display, slot: number - 1)] = Self.model(of: file.deviceName) ?? display.shortTitle
        }
        var rows = resolved.map { row(for: $0.file, locale: $0.locale, fitting: fitting) }
        rows += unresolved.map { code, files in localeRow(code: code, files: files) }
        return rows.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    // MARK: - One file

    private func row(for file: CaptureCandidate, locale: String, fitting: [CaptureMatchRow.Placement: String]) -> CaptureMatchRow {
        let skip = CaptureMatchRow.Option(choice: .skip, title: String(localized: "Skip"))
        guard let display = file.displayType, let number = file.slotNumber else {
            return .needsYou([file], issue: .unknownDevice(size: file.pixelSize), placement: nil, options: [skip])
        }
        let placement = CaptureMatchRow.Placement(locale: locale, displayType: display, slot: number - 1)
        if number > ScreenshotTemplate.maximumSlots {
            return .needsYou([file], issue: .tooManySlots(number: number), placement: placement, options: [skip])
        }
        if let slotCount, number > slotCount {
            let add = CaptureMatchRow.Option(choice: .addSlot(number), title: String(localized: "Add slot \(number) to the template"))
            return .needsYou([file], issue: .extraSlot(number: number, slotCount: slotCount), placement: placement, options: [skip, add])
        }
        if let size = file.pixelSize, !CaptureSizeRules.fits(size, in: display) {
            let percent = Int((CaptureSizeRules.scale(of: size, in: display) * 100).rounded())
            let skipTitle = fitting[placement].map { String(localized: "Skip it, the \($0) capture is there") } ?? String(localized: "Skip it")
            let options = [
                CaptureMatchRow.Option(choice: .skip, title: skipTitle),
                CaptureMatchRow.Option(choice: .scaleUp, title: String(localized: "Use it, scaled up \(percent)%")),
            ]
            return .needsYou([file], issue: .smallerDevice(deviceName: file.deviceName, size: size, display: display), placement: placement, options: options)
        }
        return .matched(file, at: placement)
    }

    /// One row for every file under a folder that isn't an App Store
    /// locale: pick one of its candidates, or skip them all.
    private func localeRow(code: String, files: [CaptureCandidate]) -> CaptureMatchRow {
        let skipTitle = files.count == 1 ? String(localized: "Skip it") : String(localized: "Skip these \(files.count) files")
        let skip = CaptureMatchRow.Option(choice: .skip, title: skipTitle)
        guard case let .ambiguous(candidates) = StoreLocaleCatalog.resolve(code) else {
            return .needsYou(files, issue: .unknownLocale(code: code.isEmpty ? nil : code), placement: nil, options: [skip])
        }
        let options = candidates.map { CaptureMatchRow.Option(choice: .locale($0.code), title: $0.name) } + [skip]
        return .needsYou(files, issue: .ambiguousLocale(code: code, candidates: candidates), placement: nil, options: options)
    }

    // MARK: - Filling in

    /// "iPhone 17 Pro Max" → "17 Pro Max".
    private static func model(of deviceName: String?) -> String? {
        guard let deviceName else { return nil }
        for family in ["iPhone ", "iPad "] where deviceName.hasPrefix(family) {
            return String(deviceName.dropFirst(family.count))
        }
        return deviceName
    }

    private static func withDisplayType(_ file: CaptureCandidate) -> CaptureCandidate {
        var file = file
        if file.displayType == nil {
            file.displayType = CaptureSizeRules.displayType(pixelSize: file.pixelSize, deviceName: file.deviceName)
        }
        return file
    }

    /// Files without a slot number take their place in name order within
    /// their locale and display type.
    private static func numbered(_ files: [CaptureCandidate]) -> [CaptureCandidate] {
        var next: [String: Int] = [:]
        return files.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }.map { file in
            guard file.slotNumber == nil else { return file }
            var file = file
            let group = "\(file.localeCode ?? "")|\(file.displayType?.rawValue ?? "")"
            let number = (next[group] ?? 0) + 1
            next[group] = number
            file.slotNumber = number
            return file
        }
    }
}
