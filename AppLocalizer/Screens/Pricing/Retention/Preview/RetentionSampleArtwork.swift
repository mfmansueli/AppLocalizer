//
//  RetentionSampleArtwork.swift
//  AppLocalizer
//

import SwiftUI

/// The sample data's library images, drawn: Moonrise, Pages and Moons,
/// Night Window and Still Lake (`sample:moon`, `pages`, `window`, `lake`).
struct RetentionSampleArtwork: View {
    let name: String

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                background
                if hasMoon {
                    let size = proxy.size.height * 0.3
                    Circle()
                        .fill(Color(red: 1, green: 0.96, blue: 0.84))
                        .frame(width: size, height: size)
                        .offset(x: proxy.size.width * 0.84 - size / 2, y: proxy.size.height * 0.36 - size / 2)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var hasMoon: Bool { name != "pages" }

    @ViewBuilder
    private var background: some View {
        switch name {
        case "pages":
            LinearGradient(stops: [
                .init(color: Self.color(0x8C86F5), location: 0),
                .init(color: Self.color(0x4A43C9), location: 0.6),
                .init(color: Self.color(0x2B2668), location: 1),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "window":
            LinearGradient(colors: [Self.color(0x1B1A3A), Self.color(0x3B3470)], startPoint: .top, endPoint: .bottom)
        case "lake":
            LinearGradient(stops: [
                .init(color: Self.color(0x4A43C9), location: 0),
                .init(color: Self.color(0x2B2668), location: 0.55),
                .init(color: Self.color(0x1A2A4A), location: 0.56),
                .init(color: Self.color(0x0E1A30), location: 1),
            ], startPoint: .top, endPoint: .bottom)
        default:
            LinearGradient(colors: [Self.color(0x6E66E8), Self.color(0x2B2668)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private static func color(_ hex: Int) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
