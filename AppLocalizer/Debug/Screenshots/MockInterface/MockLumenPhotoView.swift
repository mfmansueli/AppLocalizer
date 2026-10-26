//
//  MockLumenPhotoView.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// An entry with a photo: sky, sun and hills.
struct MockLumenPhotoView: View {
    let strings: MockLumenStrings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.photoDate).font(.system(size: 12, weight: .semibold)).foregroundStyle(MockLumenPalette.secondary)
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color(red: 0.62, green: 0.82, blue: 0.97), Color(red: 0.85, green: 0.93, blue: 0.99)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Circle().fill(Color(red: 1, green: 0.93, blue: 0.6)).frame(width: 54).offset(x: 80, y: -140)
                Ellipse().fill(Color(red: 0.36, green: 0.62, blue: 0.5)).frame(width: 520, height: 170).offset(x: -60, y: 70)
                Ellipse().fill(Color(red: 0.27, green: 0.5, blue: 0.42)).frame(width: 460, height: 150).offset(x: 140, y: 85)
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(strings.photoCaption).font(.system(size: 20, weight: .semibold)).foregroundStyle(MockLumenPalette.ink)
            MockLumenPlaceholder(width: 320)
            MockLumenPlaceholder(width: 280)
            MockLumenPlaceholder(width: 200)
        }
    }
}
#endif
