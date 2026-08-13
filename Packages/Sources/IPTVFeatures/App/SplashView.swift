import SwiftUI
import IPTVDesignSystem

/// Pantalla de arranque mientras se decide si hay sesión guardada. Dark-first:
/// evita el "fogonazo" blanco y el parpadeo del login antes de restaurar la sesión.
struct SplashView: View {
    var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "tv.inset.filled")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignTokens.Palette.accentGradient)

                Text("SuperTV")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DesignTokens.Palette.textPrimary)

                ProgressView()
                    .tint(DesignTokens.Palette.accent)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
        }
    }
}
