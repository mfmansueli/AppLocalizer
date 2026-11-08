//
//  TemplateStarter.swift
//  AppLocalizer
//

import Foundation

/// The templates the gallery offers, in four styles. Each makes a complete
/// template for every language and device; switching keeps captions and
/// captures. The three simple ones are also what Autopilot starts from
/// without a design project.
enum TemplateStarter: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    /// A headline over a framed device, on brand colors.
    case above
    /// The capture fills the screenshot; a solid band carries the caption.
    case band
    /// One background runs across every slot.
    case panorama
    case boldStack
    case cinema
    case sparkle
    case spotlight
    case swoosh
    case poster
    case editorial
    case playful
    case highlight
    case socialProof = "proof"
    case arcade

    /// The gallery's filters.
    enum Style: String, Hashable, Sendable, CaseIterable, Identifiable {
        case simple
        case bold
        case elegant
        case playful

        var id: String { rawValue }

        var title: String {
            switch self {
            case .simple: String(localized: "Simple")
            case .bold: String(localized: "Bold")
            case .elegant: String(localized: "Elegant")
            case .playful: String(localized: "Playful")
            }
        }
    }

    var id: String { rawValue }

    /// The starters Autopilot recolors from the app icon.
    static let simple: [TemplateStarter] = [.above, .band, .panorama]

    /// The starters of `style`, or all of them for nil.
    static func starters(in style: Style?) -> [TemplateStarter] {
        allCases.filter { style == nil || $0.style == style }
    }

    /// Added lately: marked “New” where templates are picked.
    var isNew: Bool { self == .socialProof || self == .arcade }

    var style: Style {
        switch self {
        case .above, .band, .panorama: .simple
        case .boldStack, .swoosh, .poster, .socialProof, .arcade: .bold
        case .cinema, .spotlight, .editorial: .elegant
        case .sparkle, .playful, .highlight: .playful
        }
    }

    var title: String {
        switch self {
        case .above: String(localized: "Caption above device")
        case .band: String(localized: "Full-bleed with caption band")
        case .panorama: String(localized: "Panorama")
        case .boldStack: String(localized: "Bold Stack")
        case .cinema: String(localized: "Cinema")
        case .sparkle: String(localized: "Sparkle")
        case .spotlight: String(localized: "Spotlight")
        case .swoosh: String(localized: "Swoosh")
        case .poster: String(localized: "Poster")
        case .editorial: String(localized: "Editorial")
        case .playful: String(localized: "Playful")
        case .highlight: String(localized: "Highlight")
        case .socialProof: String(localized: "Social Proof")
        case .arcade: String(localized: "Arcade")
        }
    }

    var summary: String {
        switch self {
        case .above: String(localized: "A headline over a framed device, on your brand colors. Works for almost any app.")
        case .band: String(localized: "The capture fills the screenshot and a solid band carries the caption. Shows the most of your interface.")
        case .panorama: String(localized: "One background runs across every slot, so the set reads as one scene when people swipe.")
        case .boldStack:
            String(localized: "Heavy uppercase over a lighter first line, angled phones and a rating laurel on warm paper. Slot 1 flips to ink.")
        case .cinema: String(localized: "A serif caption under a phone that leans out of the top, on a deep red fade. Made for media apps.")
        case .sparkle:
            String(localized: "Friendly headlines that land on a bold last line, sparkles, and a tilted phone on purple. Slot 3 turns light.")
        case .spotlight:
            String(localized: "Big serif headlines on a magenta glow, a phone lying back in perspective, and a rating laurel on slot 4.")
        case .swoosh:
            String(localized: "Green and white trade places from slot to slot, a ribbon runs behind the phone, and a badge marks slot 3.")
        case .poster: String(localized: "Tall condensed uppercase on black and grey, with bold white shapes. Loud, simple, and easy to read small.")
        case .editorial: String(localized: "A light first line over a bold statement, aligned left, on dusk and lavender. Calm and confident.")
        case .playful: String(localized: "A hand-lettered script with a soft drop shadow, white petal shapes and a laurel. Warm and casual.")
        case .highlight: String(localized: "Every line sits on its own tilted marker, with a purple phone and a laurel on slot 1.")
        case .socialProof:
            String(localized: """
            A light kicker over a heavy headline on ink, lilac and mist. Big tilted phones bleed off the edge; slot 2 is real \
            App Store reviews; slot 3 has an illustration and slot 5 a hand holding the phone.
            """)
        case .arcade:
            String(localized: """
            Huge white caps on electric blue, big straight phones that run off the bottom, hand-drawn marks and props. Slot 3 \
            stacks two phones, and one figure spans slots 4 and 5.
            """)
        }
    }

    /// The gallery card's pills.
    var tags: [String] {
        switch self {
        case .above: [String(localized: "Caption above"), String(localized: "Gradient")]
        case .band: [String(localized: "Full bleed"), String(localized: "Band")]
        case .panorama: [String(localized: "Panorama"), String(localized: "Serif")]
        case .boldStack: [String(localized: "Uppercase"), String(localized: "Angled phone"), String(localized: "Rating")]
        case .cinema: [String(localized: "Serif"), String(localized: "Caption below"), String(localized: "3D phone")]
        case .sparkle: [String(localized: "Bold last line"), String(localized: "Sparkles"), String(localized: "Two tones")]
        case .spotlight: [String(localized: "Serif"), String(localized: "Phone in perspective"), String(localized: "Rating")]
        case .swoosh: [String(localized: "Two colors"), String(localized: "Ribbon"), String(localized: "Badge")]
        case .poster: [String(localized: "Condensed"), String(localized: "Uppercase"), String(localized: "Shapes")]
        case .editorial: [String(localized: "Left aligned"), String(localized: "Light first line"), String(localized: "Angled phone")]
        case .playful: [String(localized: "Script"), String(localized: "Petal shapes"), String(localized: "Rating")]
        case .highlight: [String(localized: "Marker bars"), String(localized: "Rounded type"), String(localized: "Rating")]
        case .socialProof: [String(localized: "Kicker line"), String(localized: "Reviews slot"), String(localized: "Hand and illustration")]
        case .arcade: [String(localized: "Condensed caps"), String(localized: "Two phones"), String(localized: "Props across slots")]
        }
    }
}
