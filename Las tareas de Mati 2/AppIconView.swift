import SwiftUI

struct AppIconView: View {
    let size: CGFloat

    private var cornerRadius: CGFloat { size * 0.2237 }

    var body: some View {
        ZStack {
            base
            colorBlobs
            glassCard
            topSheen
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var base: some View {
        LinearGradient(
            colors: [
                Color(red: 0.94, green: 0.92, blue: 0.98),
                Color(red: 0.78, green: 0.74, blue: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var colorBlobs: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.55, green: 0.42, blue: 0.96).opacity(0.7))
                .frame(width: size * 0.75, height: size * 0.75)
                .blur(radius: size * 0.18)
                .offset(x: -size * 0.18, y: -size * 0.18)

            Circle()
                .fill(Color(red: 0.96, green: 0.44, blue: 0.72).opacity(0.45))
                .frame(width: size * 0.5, height: size * 0.5)
                .blur(radius: size * 0.14)
                .offset(x: -size * 0.05, y: size * 0.28)

            Circle()
                .fill(Color(red: 0.35, green: 0.6, blue: 1.0).opacity(0.5))
                .frame(width: size * 0.55, height: size * 0.55)
                .blur(radius: size * 0.14)
                .offset(x: size * 0.25, y: -size * 0.22)

            Circle()
                .fill(Color(red: 0.98, green: 0.6, blue: 0.4).opacity(0.35))
                .frame(width: size * 0.4, height: size * 0.4)
                .blur(radius: size * 0.12)
                .offset(x: size * 0.28, y: size * 0.3)
        }
    }

    private var glassCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.13, style: .continuous)
                .fill(Color.white.opacity(0.32))

            RoundedRectangle(cornerRadius: size * 0.13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.plusLighter)

            RoundedRectangle(cornerRadius: size * 0.13, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(size * 0.006, 1)
                )

            Image(systemName: "checkmark")
                .font(.system(size: size * 0.3, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.32, blue: 0.96),
                            Color(red: 0.65, green: 0.5, blue: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.4, green: 0.28, blue: 0.92).opacity(0.5), radius: size * 0.015)
        }
        .frame(width: size * 0.58, height: size * 0.58)
        .shadow(color: Color.black.opacity(0.22), radius: size * 0.04, x: 0, y: size * 0.025)
    }

    private var topSheen: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.18),
                Color.white.opacity(0)
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.4)
        )
        .allowsHitTesting(false)
    }
}

#Preview("App Icon — sizes") {
    HStack(spacing: 24) {
        AppIconView(size: 512)
        VStack(spacing: 16) {
            AppIconView(size: 128)
            HStack(spacing: 12) {
                AppIconView(size: 64)
                AppIconView(size: 32)
                AppIconView(size: 16)
            }
        }
    }
    .padding(40)
    .background(Color.gray.opacity(0.15))
}
