//
//  PrivacySummaryPDFWriter.swift
//  AppLocalizer
//

import AppKit
import CoreText

/// Lays the Markdown summary out on US Letter pages: `#` lines as the
/// title, `##` lines as headings, the rest as body text.
enum PrivacySummaryPDFWriter {
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 54

    static func pdf(from markdown: String) -> Data {
        let text = attributedText(from: markdown)
        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return Data() }
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let frameRect = mediaBox.insetBy(dx: margin, dy: margin)
        var location = 0
        repeat {
            context.beginPDFPage(nil)
            let path = CGPath(rect: frameRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: location, length: 0), path, nil)
            CTFrameDraw(frame, context)
            let visible = CTFrameGetVisibleStringRange(frame)
            location += max(visible.length, 1)
            context.endPDFPage()
        } while location < text.length
        context.closePDF()
        return data as Data
    }

    private static func attributedText(from markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for line in markdown.components(separatedBy: "\n") {
            let (text, font): (String, NSFont) = if line.hasPrefix("## ") {
                (String(line.dropFirst(3)), .boldSystemFont(ofSize: 13))
            } else if line.hasPrefix("# ") {
                (String(line.dropFirst(2)), .boldSystemFont(ofSize: 20))
            } else {
                (line, .systemFont(ofSize: 11))
            }
            let style = NSMutableParagraphStyle()
            style.paragraphSpacingBefore = font.pointSize > 11 ? 6 : 0
            style.paragraphSpacing = 2
            result.append(NSAttributedString(string: text + "\n", attributes: [
                .font: font,
                .paragraphStyle: style,
            ]))
        }
        return result
    }
}
