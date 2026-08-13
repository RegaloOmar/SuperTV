import SwiftUI
import ComposableArchitecture
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
        #if DEBUG
        // Hook de DEBUG para demos / UI tests: rellena el login vía launch arguments.
        // p. ej. `-demoHost demo.tv:8080 -demoUser user -demoPass pass -demoAutoConnect`.
        let args = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if let host = value(after: "-demoHost") { state.auth.host = host }
        if let user = value(after: "-demoUser") { state.auth.username = user }
        if let pass = value(after: "-demoPass") { state.auth.password = pass }
        autoConnect = args.contains("-demoAutoConnect")
        #endif
        self.demoAutoConnect = autoConnect
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
