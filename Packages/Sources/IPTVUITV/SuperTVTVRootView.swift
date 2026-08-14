#if os(tvOS)
import SwiftUI
import ComposableArchitecture
import IPTVFeatures
import IPTVDesignSystem

/// Punto de entrada de la UI de tvOS. Reutiliza los reducers de `IPTVFeatures`
/// (misma lógica que iPhone/iPad); las vistas son propias de tvOS (focus/mando).
public struct SuperTVTVRootView: View {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    public init() {
        // Caché amplia para logos de canal (los IPTV pesan).
        URLCache.shared = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 512 * 1024 * 1024)
    }

    public var body: some View {
        TVAppView(store: store)
            .preferredColorScheme(.dark)
            .tint(DesignTokens.Palette.accent)
    }
}

/// Navegación de tvOS: splash → login → categorías → (push) canales; reproductor y
/// ajustes como pantalla completa. Mismo modelo de estado que iPhone/iPad.
struct TVAppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack {
            Group {
                if store.isLaunching {
                    TVSplashView()
                } else if let channelListStore = store.scope(state: \.channelList, action: \.channelList) {
                    TVCategoriesView(store: channelListStore)
                } else {
                    TVAuthView(store: store.scope(state: \.auth, action: \.auth))
                }
            }
            .navigationDestination(item: $store.scope(state: \.channels, action: \.channels)) { channelsStore in
                TVChannelsView(store: channelsStore)
            }
            .task { store.send(.onLaunch) }
        }
        .fullScreenCover(item: $store.scope(state: \.player, action: \.player)) { playerStore in
            TVPlayerView(store: playerStore)
        }
        .fullScreenCover(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
            TVSettingsView(store: settingsStore)
        }
    }
}

/// Pantalla de arranque de tvOS.
struct TVSplashView: View {
    var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()
            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "tv.inset.filled")
                    .font(.system(size: 120))
                    .foregroundStyle(DesignTokens.Palette.accentGradient)
                Text("SuperTV")
                    .font(.system(size: 90, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
                ProgressView().tint(DesignTokens.Palette.accent)
            }
        }
    }
}
#endif
