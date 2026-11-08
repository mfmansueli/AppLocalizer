//
//  RetentionPhone.swift
//  AppLocalizer
//

import SwiftUI

/// Apple's Confirm Cancellation screen on an iPhone, in light or dark, with
/// the message (and its image or offer) in the "From the developer" card.
/// Its own colors, so it looks like the phone whatever the Mac's
/// appearance.
struct RetentionPhone: View {
    let app: StoreApp
    let strings: RetentionCancelStrings
    let endText: String
    let header: String
    let messageBody: String
    var image: RetentionImage?
    /// The subscription group's name and the offer's line, when it shows one.
    var offer: (group: String, line: String)?
    let isDark: Bool
    let isRightToLeft: Bool

    static let size = CGSize(width: 240, height: 500)

    private var background: Color { isDark ? .black : Color(red: 0.95, green: 0.95, blue: 0.97) }
    private var card: Color { isDark ? Color(red: 0.11, green: 0.11, blue: 0.12) : .white }
    private var ink: Color { isDark ? .white : .black }
    private var secondary: Color { isDark ? Color(white: 0.92).opacity(0.6) : Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6) }
    private var edge: Color { isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.12) }
    private var blue: Color { isDark ? Color(red: 0.04, green: 0.52, blue: 1) : Color(red: 0, green: 0.48, blue: 1) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.78), Color(white: 0.55), Color(white: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.black)
                .padding(3)
            screen
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .padding(8)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .environment(\.colorScheme, isDark ? .dark : .light)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Preview: \(strings.title). \(header). \(messageBody)"))
        .accessibilityIdentifier("retention.preview.phone")
    }

    private var screen: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBar
            VStack(alignment: .leading, spacing: 6) {
                AppIconTile(name: app.name, icon: app.icon, size: 34)
                    .padding(.bottom, 2)
                Text(strings.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ink)
                Text(endText)
                    .font(.system(size: 10.5))
                    .foregroundStyle(secondary)
                    .fixedSize(horizontal: false, vertical: true)
                messageCard
                    .padding(.top, 4)
            }
            .padding(.horizontal, 14)
            .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 8)
            VStack(spacing: 7) {
                phoneButton(strings.cancel)
                phoneButton(strings.keep)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(background)
    }

    private var statusBar: some View {
        ZStack {
            Capsule()
                .fill(Color.black)
                .frame(width: 66, height: 19)
            HStack {
                Text(verbatim: "9:41")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 20)
        }
        .frame(height: 30)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(strings.from)
                .font(.system(size: 7.5, weight: .semibold))
                .foregroundStyle(secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            Rectangle().fill(edge).frame(height: 0.5)
            if let image {
                RetentionArtworkView(image: image)
                    .frame(height: 194 * CGFloat(image.pixelHeight) / CGFloat(max(1, image.pixelWidth)))
                    .frame(maxWidth: .infinity)
                    .environment(\.layoutDirection, .leftToRight)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(header.isEmpty ? "—" : header)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ink)
                Text(messageBody)
                    .font(.system(size: 9.5))
                    .foregroundStyle(ink.opacity(0.85))
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            if let offer { offerBlock(offer) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(edge, lineWidth: 0.5) }
    }

    private func offerBlock(_ offer: (group: String, line: String)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(edge).frame(height: 0.5)
            HStack(spacing: 7) {
                AppIconTile(name: app.name, icon: app.icon, size: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(offer.group)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(ink)
                    Text(offer.line)
                        .font(.system(size: 8))
                        .foregroundStyle(secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 10)
            Text(strings.accept)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(blue.opacity(0.12), in: Capsule())
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
    }

    private func phoneButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(blue)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(card, in: Capsule())
    }
}
