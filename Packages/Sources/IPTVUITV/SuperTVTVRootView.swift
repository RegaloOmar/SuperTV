#if os(tvOS)
import SwiftUI
import ComposableArchitecture
import Dependencies
import IPTVCore
import IPTVFeatures
import IPTVDesignSystem

/// Punto de entrada de la UI de tvOS. Reutiliza los reducers de `IPTVFeatures`
/// (misma lógica que iPhone/iPad); las vistas son propias de tvOS (focus/mando).
public struct SuperTVTVRootView: View {
    @State private var store: StoreOf<AppFeature>

    public init() {
        // Caché amplia para logos de canal (los IPTV pesan).
        URLCache.shared = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 512 * 1024 * 1024)

        var state = AppFeature.State()
        var demoCatalog = false
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demoCatalog") {
            demoCatalog = true
            let account = IPTVAccount(host: URL(string: "http://demo.local")!, username: "demo", password: "demo")
            state.session = .init(
                account: account,
                status: AccountStatus(state: .active, expiresAt: nil, isTrial: false, activeConnections: 1, maxConnections: 2)
            )
            state.channelList = ChannelListFeature.State(account: account)
            state.isLaunching = false
            if ProcessInfo.processInfo.arguments.contains("-demoCatalogChannels") {
                state.channels = ChannelsFeature.State(account: account, category: ChannelCategory(id: "1", name: "Sports"))
            }
        }
        #endif

        #if DEBUG
        if demoCatalog {
            _store = State(initialValue: withDependencies {
                $0.channelRepository = DemoCatalogRepository()
            } operation: {
                Store(initialState: state) { AppFeature() }
            })
            return
        }
        #endif
        _store = State(initialValue: Store(initialState: state) { AppFeature() })
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

#if DEBUG
/// Catálogo de prueba para visualizar el diseño de tvOS (`-demoCatalog`).
private struct DemoCatalogRepository: ChannelRepositoryProtocol {
    func categories(for account: IPTVAccount, forceRefresh: Bool) async throws -> [ChannelCategory] {
        [
            ChannelCategory(id: "1", name: "Sports", displayOrder: 0),
            ChannelCategory(id: "2", name: "News", displayOrder: 1),
            ChannelCategory(id: "3", name: "Movies", displayOrder: 2),
            ChannelCategory(id: "4", name: "Series", displayOrder: 3),
            ChannelCategory(id: "5", name: "Kids", displayOrder: 4),
            ChannelCategory(id: "6", name: "Documentaries", displayOrder: 5),
        ]
    }
    func channels(for account: IPTVAccount, categoryID: String?, forceRefresh: Bool) async throws -> [Channel] {
        [
            Channel(id: 1, name: "ESPN Deportes HD", categoryID: "1", channelNumber: 101),
            Channel(id: 2, name: "Fox Sports Premium", categoryID: "1", channelNumber: 205),
            Channel(id: 3, name: "DAZN LaLiga", categoryID: "1", channelNumber: 312),
            Channel(id: 4, name: "Movistar Deportes", categoryID: "1", channelNumber: 418),
            Channel(id: 5, name: "Eurosport 1", categoryID: "1", channelNumber: 520),
            Channel(id: 6, name: "GolTV", categoryID: "1", channelNumber: 601),
        ]
    }
    func clearCache() async throws {}
}
#endif
#endif
