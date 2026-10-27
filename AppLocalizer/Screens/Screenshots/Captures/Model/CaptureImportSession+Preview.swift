//
//  CaptureImportSession+Preview.swift
//  AppLocalizer
//

import Foundation

extension CaptureImportSession {
    /// A few matched rows from as many locales and display types as fit,
    /// the primary locale's first: one from each in turn, so the collapsed
    /// list shows the spread of the import rather than one folder.
    func matchedPreview(count: Int, primary: String) -> [CaptureMatchRow] {
        let matched = rows.filter { !$0.needsYou }
        let ordered = matched.filter { $0.placement?.locale == primary } + matched.filter { $0.placement?.locale != primary }
        var groups: [[CaptureMatchRow]] = []
        var groupIndex: [CaptureGroupKey: Int] = [:]
        for row in ordered {
            let key = CaptureGroupKey(locale: row.placement?.locale, displayType: row.placement?.displayType)
            if let index = groupIndex[key] {
                groups[index].append(row)
            } else {
                groupIndex[key] = groups.count
                groups.append([row])
            }
        }
        var preview: [CaptureMatchRow] = []
        var round = 0
        while preview.count < count, groups.contains(where: { $0.count > round }) {
            for group in groups where group.count > round && preview.count < count {
                preview.append(group[round])
            }
            round += 1
        }
        return preview
    }

    private struct CaptureGroupKey: Hashable {
        var locale: String?
        var displayType: ScreenshotDisplayType?
    }
}
