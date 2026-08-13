import SwiftUI
import ComposableArchitecture
import Dependencies
import IPTVCore
import IPTVDesignSystem

/// Punto de entrada público de la UI. El app target (Xcode) solo conoce esto:
/// crea y retiene el `Store`, de modo que la capa de App no importa TCA.
public struct SuperTVRootView: View {
    @State private var store: StoreOf<AppFeature>
    private let demoAutoConnect: Bool

    public init() {
        // Caché amplia para logos de canal (los IPTV pesan). AsyncImage usa URLCache.shared.
        URLCache.shared = URLCache(
            memoryCapacity: 32 * 1024 * 1024,   // 32 MB en memoria
            diskCapacity: 256 * 1024 * 1024     // 256 MB en disco
        )

        var state = AppFeature.State()
        var autoConnect = false
        var demoStreamURL: URL?
        var demoCatalog = false
        #if DEBUG
        // Hook de DEBUG para demos / UI tests: rellena el login vía launch arguments.
        // p. ej. `-demoHost demo.tv:8080 -demoUser user -demoPass pass -demoAutoConnect`.
        // `-demoPlayHLS <url>` arranca directo en el reproductor con un stream de prueba.
        let args = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if let host = value(after: "-demoHost") { state.auth.host = host }
        if let user = value(after: "-demoUser") { state.auth.username = user }
        if let pass = value(after: "-demoPass") { state.auth.password = pass }
        autoConnect = args.contains("-demoAutoConnect")

        if let hls = value(after: "-demoPlayHLS"), let url = URL(string: hls) {
            demoStreamURL = url
            let account = IPTVAccount(host: URL(string: "http://demo.local")!, username: "demo", password: "demo")
            state.session = .init(
                account: account,
                status: AccountStatus(state: .active, expiresAt: nil, isTrial: false, activeConnections: 1, maxConnections: 1)
            )
            state.channelList = ChannelListFeature.State(account: account)
            state.player = PlayerFeature.State(
                channel: Channel(id: 999, name: "Demo HLS", categoryID: "0"),
                account: account
            )
        }

        // `-demoCatalog` abre la pantalla de canales con datos de prueba (para diseño).
        if args.contains("-demoCatalog") {
            demoCatalog = true
            let account = IPTVAccount(host: URL(string: "http://demo.local")!, username: "demo", password: "demo")
            state.session = .init(
                account: account,
                status: AccountStatus(state: .active, expiresAt: nil, isTrial: false, activeConnections: 1, maxConnections: 2)
            )
            state.channelList = ChannelListFeature.State(account: account)
            // Con `-demoCatalogChannels` salta directo a los canales; si no, se queda
            // en la lista de categorías.
            if args.contains("-demoCatalogChannels") {
                state.path.append(.channels(ChannelsFeature.State(
                    account: account,
                    category: ChannelCategory(id: "1", name: "Deportes")
                )))
            }
        }

        // Con cualquier hook de demo, saltar el splash de arranque.
        if args.contains(where: { $0.hasPrefix("-demo") }) {
            state.isLaunching = false
        }
        #endif
        self.demoAutoConnect = autoConnect

        #if DEBUG
        if demoStreamURL != nil || demoCatalog {
            let streamURL = demoStreamURL
            _store = State(initialValue: withDependencies {
                if let streamURL { $0.playableStreamProvider = DemoStreamProvider(url: streamURL) }
                if demoCatalog { $0.channelRepository = DemoCatalogRepository() }
            } operation: {
                Store(initialState: state) { AppFeature() }
            })
            return
        }
        #endif
        _store = State(initialValue: Store(initialState: state) { AppFeature() })
    }

    public var body: some View {
        AppView(store: store)
            .task {
                guard demoAutoConnect else { return }
                store.send(.auth(.loginButtonTapped))
            }
    }
}

#if DEBUG
/// Proveedor de prueba que resuelve cualquier canal a una URL HLS fija (para `-demoPlayHLS`).
private struct DemoStreamProvider: PlayableStreamProviding {
    let url: URL
    func stream(for channel: Channel, account: IPTVAccount) throws -> LiveStream {
        LiveStream(channelID: channel.id, url: url, container: .hls)
    }
}

/// Catálogo de prueba para visualizar el diseño (para `-demoCatalog`).
private struct DemoCatalogRepository: ChannelRepositoryProtocol {
    func categories(for account: IPTVAccount, forceRefresh: Bool) async throws -> [ChannelCategory] {
        [
            ChannelCategory(id: "1", name: "Deportes", displayOrder: 0),
            ChannelCategory(id: "2", name: "Noticias", displayOrder: 1),
            ChannelCategory(id: "3", name: "Películas", displayOrder: 2),
            ChannelCategory(id: "4", name: "Series", displayOrder: 3),
            ChannelCategory(id: "5", name: "Infantil", displayOrder: 4),
            ChannelCategory(id: "6", name: "Documentales", displayOrder: 5),
            ChannelCategory(id: "7", name: "Música", displayOrder: 6),
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
            Channel(id: 7, name: "NBA League Pass", categoryID: "1", channelNumber: 733),
            Channel(id: 8, name: "UFC Fight Network", categoryID: "1", channelNumber: 840),
        ]
    }
    func clearCache() async throws {}
}
#endif

/// Vista raíz. Enruta entre login y categorías según haya sesión, dentro de un
/// `NavigationStack` dirigido por `StackState`.
public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            Group {
                if store.isLaunching {
                    SplashView()
                } else if let channelListStore = store.scope(state: \.channelList, action: \.channelList) {
                    ChannelListView(store: channelListStore)
                } else {
                    AuthView(store: store.scope(state: \.auth, action: \.auth))
                }
            }
            .task { store.send(.onLaunch) }
        } destination: { store in
            switch store.case {
            case .channels(let store):
                ChannelsView(store: store)
            case .settings(let store):
                SettingsView(store: store)
            }
        }
        #if os(iOS)
        // El reproductor se presenta a pantalla completa (solo iOS; en macOS el paquete
        // solo se compila para los tests, que no presentan UI).
        .fullScreenCover(item: $store.scope(state: \.player, action: \.player)) { playerStore in
            PlayerView(store: playerStore)
        }
        #endif
        // Estética SuperTV: negro + oro rosa. Dark-first (sin fogonazo blanco en TV).
        .tint(DesignTokens.Palette.accent)
        .preferredColorScheme(.dark)
    }
}
