//
//  ScreenshotsSampleData+Proposals.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

// Claude Code's screenshot proposals in the design: a template revision
// at 10:42 and shorter German captions at 10:43 (today, so the sheet shows
// times alone), and for `prop-stale` one from Oct 20 based on v3.
extension ScreenshotsSampleData {
    static let assistant = "Claude Code"

    /// Today at `hour`:`minute`.
    static func today(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    static var proposals: [ScreenshotProposal] { [templateProposal, captionProposal] }

    /// p1: "Smaller headline, hyphenation on", v4 → v5, four changes.
    static var templateProposal: ScreenshotProposal {
        .template(
            id: "p1", client: assistant, receivedAt: today(10, 42), title: "Smaller headline, hyphenation on",
            reason: """
            German and Finnish shrink to the smallest size or overflow in three slots. A slightly smaller headline with \
            hyphenation for long words keeps every locale on two lines, and English stays at full size.
            """,
            proposal: TemplateProposal(basedOn: 4, operations: [
                .replace("caption.headline.size", with: 104),
                .replace("caption.headline.min", with: 72),
                .replace("fit.hyphenate", with: true),
                .replace("device.width", with: .double(0.78)),
            ])
        )
    }

    /// p2: "Shorter German captions" for slots 2, 3 and 5.
    static var captionProposal: ScreenshotProposal {
        let items = (shorterCaptions["de-DE"] ?? [:]).sorted { $0.key < $1.key }.map { slot, headline in
            CaptionProposalItem(locale: "de-DE", slot: slot, headline: headline)
        }
        return .captions(
            id: "p2", client: assistant, receivedAt: today(10, 43), title: "Shorter German captions",
            reason: """
            These three German captions are the longest in the set. The shorter versions keep the meaning and fit at full \
            size, so the German screenshots look as calm as the English ones.
            """,
            items: items
        )
    }

    /// p3: "More room above the caption", based on v3, from Oct 20.
    static var staleProposal: ScreenshotProposal {
        .template(
            id: "p3", client: assistant, receivedAt: date(month: 10, day: 20, hour: 18, minute: 5), title: "More room above the caption",
            reason: """
            Captions sit close to the top edge on iPad landscape. Moving them down and shrinking the device a little \
            gives the headline more air.
            """,
            proposal: TemplateProposal(basedOn: 3, operations: [
                .replace("safe.top", with: .double(0.08)),
                .replace("device.width", with: .double(0.76)),
            ])
        )
    }

    /// For `prop-stale`: v4 also narrowed the device, 80% → 78%.
    static var staleHistory: TemplateHistory {
        var latest = template
        latest.device.width = 0.78
        return history(latest: latest, note: "Device width 80% → 78%")
    }
}
#endif
