//
//  MockLumenLockView.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Lumen locked behind Face ID.
struct MockLumenLockView: View {
    let strings: MockLumenStrings

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "moon.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(MockLumenPalette.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(strings.lockTitle).font(.system(size: 20, weight: .bold)).foregroundStyle(MockLumenPalette.ink)
            Text(strings.lockSubtitle).font(.system(size: 14)).foregroundStyle(MockLumenPalette.secondary)
                .multilineTextAlignment(.center)
            Image(systemName: "faceid").font(.system(size: 34)).foregroundStyle(MockLumenPalette.secondary).padding(.vertical, 10)
            Text(strings.unlock)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 10)
                .background(MockLumenPalette.accent, in: Capsule())
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
#endif
