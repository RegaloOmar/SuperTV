import SwiftUI
import ComposableArchitecture
import IPTVFeatures
import IPTVDesignSystem

/// Punto de entrada de la UI de tvOS. Reutiliza los reducers de `IPTVFeatures`
/// (misma lógica que iPhone/iPad); las vistas son propias de tvOS (focus/mando).
///
/// Primer hito: valida que todo el grafo compila para tvOS. Las pantallas reales
/// (login, categorías, canales, reproductor) se construyen a continuación.
public struct SuperTVTVRootView: View {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    public init() {}

    public var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "tv.inset.filled")
                    .font(.system(size: 120))
                    .foregroundStyle(DesignTokens.Palette.accentGradient)

                Text("SuperTV")
                    .font(.system(size: 90, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)

                Text(store.isLaunching ? "Preparando…" : "Listo")
                    .font(.title3)
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
            }
        }
        .preferredColorScheme(.dark)
        .task { store.send(.onLaunch) }
    }
}
