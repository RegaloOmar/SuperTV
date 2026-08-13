import SwiftUI
import ComposableArchitecture
import Dependencies
import IPTVCore

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
            state.path.append(.player(PlayerFeature.State(
                channel: Channel(id: 999, name: "Demo HLS", categoryID: "0"),
                account: account
            )))
        }
        #endif
        self.demoAutoConnect = autoConnect

        #if DEBUG
        if let url = demoStreamURL {
            _store = State(initialValue: withDependencies {
                $0.playableStreamProvider = DemoStreamProvider(url: url)
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
            if let channelListStore = store.scope(state: \.channelList, action: \.channelList) {
                ChannelListView(store: channelListStore)
            } else {
                AuthView(store: store.scope(state: \.auth, action: \.auth))
            }
        } destination: { store in
            switch store.case {
            case .channels(let store):
                ChannelsView(store: store)
            case .player(let store):
                PlayerView(store: store)
            case .settings(let store):
                SettingsView(store: store)
            }
        }
    }
}
