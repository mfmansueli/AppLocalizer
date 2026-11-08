//
//  DecorationArt+Library.swift
//  AppLocalizer
//

import CoreGraphics

// The props as the design draws them (Shots board, Arcade): SVG paths in
// each prop's view box, each part with its own fill, stroke and opacity;
// `.tint` takes the decoration's color. Stand-ins drawn for the template,
// never cut out of a reference.
extension DecorationArt {
    /// The drawing for `art`, its paths parsed once.
    static func drawing(for art: TemplateArt) -> DecorationArt {
        library[art] ?? DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 100), stretches: false, parts: [])
    }

    private static let library: [TemplateArt: DecorationArt] = Dictionary(uniqueKeysWithValues: TemplateArt.allCases.map { ($0, make($0)) })

    // swiftlint:disable line_length
    private static func make(_ art: TemplateArt) -> DecorationArt {
        switch art {
        case .controller:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 120, height: 84), stretches: false, parts: [
                DecorationArtPart("M22 14 C34 8 50 12 60 12 C70 12 86 8 98 14 C110 20 118 48 116 66 C115 78 104 84 95 76 C88 70 82 60 74 58 L46 58 C38 60 32 70 25 76 C16 84 5 78 4 66 C2 48 10 20 22 14 Z", fill: .color("#F4F5F8"), stroke: .color("#C3C8D4"), strokeWidth: 1.2),
                DecorationArtPart("M8 50 C6 62 8 74 16 78 C22 80 27 74 30 68 C22 70 12 64 8 50 Z M112 50 C114 62 112 74 104 78 C98 80 93 74 90 68 C98 70 108 64 112 50 Z", fill: .color("#D5D9E3")),
                DecorationArtPart("M44 14 L76 14 C77 14 78 15 78 16 L75 34 C75 35 74 36 73 36 L47 36 C46 36 45 35 45 34 L42 16 C42 15 43 14 44 14 Z", fill: .color("#E2E5ED"), stroke: .color("#C3C8D4"), strokeWidth: 0.8),
                DecorationArtPart("M22 21 h6 v6 h6 v6 h-6 v6 h-6 v-6 h-6 v-6 h6 Z M90.7 21 a3.3 3.3 0 1 0 6.6 0 a3.3 3.3 0 1 0 -6.6 0 Z M97.7 28 a3.3 3.3 0 1 0 6.6 0 a3.3 3.3 0 1 0 -6.6 0 Z M90.7 35 a3.3 3.3 0 1 0 6.6 0 a3.3 3.3 0 1 0 -6.6 0 Z M83.7 28 a3.3 3.3 0 1 0 6.6 0 a3.3 3.3 0 1 0 -6.6 0 Z", fill: .color("#3A3E49")),
                DecorationArtPart("M35.5 46 a8.5 8.5 0 1 0 17 0 a8.5 8.5 0 1 0 -17 0 Z M67.5 46 a8.5 8.5 0 1 0 17 0 a8.5 8.5 0 1 0 -17 0 Z", fill: .color("#262931")),
                DecorationArtPart("M38.8 46 a5.2 5.2 0 1 0 10.4 0 a5.2 5.2 0 1 0 -10.4 0 Z M70.8 46 a5.2 5.2 0 1 0 10.4 0 a5.2 5.2 0 1 0 -10.4 0 Z", fill: .color("#4A4F5C")),
            ])
        case .chess:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 100), stretches: false, parts: [
                DecorationArtPart("M49.1 4 h5.8 v3.8 h4.8 v4.8 h-4.8 v5.8 h-5.8 v-5.8 h-4.8 v-4.8 h4.8 Z M37.6 18.4 L66.4 18.4 L60.6 32.8 L43.4 32.8 Z M35.7 34.7 a16.3 3.4 0 1 0 32.6 0 a16.3 3.4 0 1 0 -32.6 0 Z M44.3 36.6 C43.4 69.3 30.9 80.8 28 89.4 L76 89.4 C73.1 80.8 60.6 69.3 59.7 36.6 Z M39.5 52 a12.5 2.4 0 1 0 25 0 a12.5 2.4 0 1 0 -25 0 Z M25.1 88.5 L78.9 88.5 L81.8 102 L22.2 102 Z", fill: .color("#1F8A4C")),
                DecorationArtPart("M55.8 38.6 C56.8 71.2 66.4 80.8 69.3 88.5 L76 88.5 C73.1 80.8 60.6 69.3 59.7 38.6 Z", fill: .color("#11592F")),
                DecorationArtPart("M47.2 38.6 C46.2 69.3 37.6 80.8 35.7 86.6 L41.4 86.6 C42.4 78.9 50.1 69.3 50.1 38.6 Z M39.5 19.4 L45.3 19.4 L47.2 31.8 L44.3 31.8 Z", fill: .color("#4CC27A"), opacity: 0.75),
                DecorationArtPart("M12.1 55.9 a9.9 9.9 0 1 0 19.8 0 a9.9 9.9 0 1 0 -19.8 0 Z M9.2 67.5 a12.8 2.9 0 1 0 25.6 0 a12.8 2.9 0 1 0 -25.6 0 Z M15 68.6 C15 85.4 6.3 91.2 4.6 97 L39.4 97 C37.7 91.2 29 85.4 29 68.6 Z M2.9 95.9 L41.1 95.9 L43.5 106 L0.5 106 Z", fill: .color("#1F8A4C")),
                DecorationArtPart("M24.9 69.8 C25.5 86.6 32.4 92.4 34.8 95.9 L39.4 95.9 C37.7 91.2 29 85.4 29 69.8 Z", fill: .color("#11592F")),
                DecorationArtPart("M15.3 53.5 a2.6 4.1 0 1 0 5.2 0 a2.6 4.1 0 1 0 -5.2 0 Z M17.4 70.9 C17.4 85.4 11.6 91.2 10.4 94.7 L14.5 94.7 C15 90.1 19.7 84.3 19.7 70.9 Z", fill: .color("#4CC27A"), opacity: 0.75),
                DecorationArtPart("M73.5 52.5 a10.5 10.5 0 1 0 21 0 a10.5 10.5 0 1 0 -21 0 Z M70.4 64.9 a13.6 3.1 0 1 0 27.2 0 a13.6 3.1 0 1 0 -27.2 0 Z M76.6 66.2 C76.6 84.2 67.3 90.4 65.4 96.6 L102.6 96.6 C100.7 90.4 91.4 84.2 91.4 66.2 Z M63.5 95.3 L104.5 95.3 L106.9 106 L61.1 106 Z", fill: .color("#1F8A4C")),
                DecorationArtPart("M87.1 67.4 C87.7 85.4 95.2 91.6 97.6 95.3 L102.6 95.3 C100.7 90.4 91.4 84.2 91.4 67.4 Z", fill: .color("#11592F")),
                DecorationArtPart("M76.9 50.1 a2.8 4.3 0 1 0 5.6 0 a2.8 4.3 0 1 0 -5.6 0 Z M79 68.7 C79 84.2 72.8 90.4 71.6 94.1 L75.9 94.1 C76.6 89.1 81.5 82.9 81.5 68.7 Z", fill: .color("#4CC27A"), opacity: 0.75),
            ])
        case .dice:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 100), stretches: false, parts: [
                DecorationArtPart("M50 8 L90 28 L50 48 L10 28 Z", fill: .color("#F25C5C"), stroke: .color("#F25C5C"), strokeWidth: 7),
                DecorationArtPart("M10 28 L50 48 L50 94 L10 74 Z", fill: .color("#E02A33"), stroke: .color("#E02A33"), strokeWidth: 7),
                DecorationArtPart("M50 48 L90 28 L90 74 L50 94 Z", fill: .color("#B3141E"), stroke: .color("#B3141E"), strokeWidth: 7),
                DecorationArtPart("M43 28 a7 3.8 0 1 0 14 0 a7 3.8 0 1 0 -14 0 Z M15.6 44.5 a4.4 4.4 0 1 0 8.8 0 a4.4 4.4 0 1 0 -8.8 0 Z M25.6 61 a4.4 4.4 0 1 0 8.8 0 a4.4 4.4 0 1 0 -8.8 0 Z M35.6 77.5 a4.4 4.4 0 1 0 8.8 0 a4.4 4.4 0 1 0 -8.8 0 Z M57 55.3 a4.2 4.2 0 1 0 8.4 0 a4.2 4.2 0 1 0 -8.4 0 Z M74.6 46.5 a4.2 4.2 0 1 0 8.4 0 a4.2 4.2 0 1 0 -8.4 0 Z M57 75.5 a4.2 4.2 0 1 0 8.4 0 a4.2 4.2 0 1 0 -8.4 0 Z M74.6 66.7 a4.2 4.2 0 1 0 8.4 0 a4.2 4.2 0 1 0 -8.4 0 Z", fill: .color("#FFFFFF")),
            ])
        case .person:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 140, height: 250), stretches: false, parts: [
                DecorationArtPart("M24 118 C28 100 42 90 60 88 L86 88 C104 90 118 100 122 118 L126 252 L20 252 Z", fill: .color("#1E2740")),
                DecorationArtPart("M58 90 L84 90 L90 252 L52 252 Z", fill: .color("#E5A92E")),
                DecorationArtPart("M56 92 L53 252 M86 92 L91 252", stroke: .color("#E9EDF5"), strokeWidth: 2.4),
                DecorationArtPart("M62 74 L80 74 L80 92 L62 92 Z", fill: .color("#D49A76")),
                DecorationArtPart("M49 52 a21 25 0 1 0 42 0 a21 25 0 1 0 -42 0 Z", fill: .color("#E8B48F")),
                DecorationArtPart("M48 50 C45 30 58 22 71 23 C86 23 95 33 92 50 C88 41 80 37 70 37 C60 37 52 42 48 50 Z", fill: .color("#4A3326")),
                DecorationArtPart("M60 58 q4 2.4 8 0 M75 58 q4 2.4 8 0", stroke: .color("#3A2A22"), strokeWidth: 1.8),
                DecorationArtPart("M66 69 q5 3.2 10 0", stroke: .color("#B3684B"), strokeWidth: 1.8),
                DecorationArtPart("M45 52 C42 20 98 16 96 52", stroke: .color("#15171C"), strokeWidth: 6),
                DecorationArtPart("M41 45 h9 v22 h-9 Z M92 45 h9 v22 h-9 Z", fill: .color("#15171C"), stroke: .color("#15171C"), strokeWidth: 4),
                DecorationArtPart("M22 122 C10 150 14 176 40 180 L66 170 C56 166 44 160 40 150 C38 140 36 130 34 120 Z", fill: .color("#1E2740")),
                DecorationArtPart("M122 122 C132 146 130 168 112 176 L92 168 C100 162 108 156 110 146 C112 138 112 130 110 122 Z", fill: .color("#1E2740")),
                DecorationArtPart("M38 177 L64 167 M94 166 L112 173", stroke: .color("#E9EDF5"), strokeWidth: 3),
                DecorationArtPart("M52 150 L104 142 C106 142 107 143 107 145 L109 162 C109 164 108 165 106 165 L56 172 C54 172 53 171 53 169 L51 153 C51 151 51 150 52 150 Z", fill: .color("#101114")),
                DecorationArtPart("M56 153 L102 146 L104 160 L58 167 Z", fill: .color("#2C3A5C")),
                DecorationArtPart("M48 166 a9 8 0 1 0 18 0 a9 8 0 1 0 -18 0 Z M95 158 a9 8 0 1 0 18 0 a9 8 0 1 0 -18 0 Z", fill: .color("#E8B48F")),
            ])
        case .underline:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 200, height: 30), stretches: true, parts: [
                DecorationArtPart("M8 10 C60 5 140 4 192 7", stroke: .tint, strokeWidth: 5),
                DecorationArtPart("M36 21 C90 17 150 16 184 18", stroke: .tint, strokeWidth: 4),
            ])
        case .asterisk:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 100), stretches: false, parts: [
                DecorationArtPart("M50 4 L50 96 M4 50 L96 50 M24 24 L76 76 M76 24 L24 76", stroke: .tint, strokeWidth: 4.5),
            ])
        case .arrow:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 130), stretches: false, parts: [
                DecorationArtPart("M14 10 C64 6 96 44 72 112", stroke: .tint, strokeWidth: 5),
                DecorationArtPart("M55 98 L71 114 L88 99", stroke: .tint, strokeWidth: 5),
            ])
        case .corner:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 300), stretches: true, parts: [
                DecorationArtPart("M0 0 L100 0 L100 300 C82 200 46 86 0 0 Z", fill: .tint),
            ])
        case .pointer:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 100), stretches: false, parts: [
                DecorationArtPart("M10 30 L90 8 L60 92 Z", fill: .tint, stroke: .tint, strokeWidth: 8),
            ])
        case .star:
            DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 100), stretches: true, parts: [
                DecorationArtPart("M54 0 C55 34 60 42 100 46 C62 50 56 58 52 100 C49 60 44 52 0 54 C42 48 50 40 54 0 Z", fill: .tint),
            ])
        }
    }
    // swiftlint:enable line_length
}
