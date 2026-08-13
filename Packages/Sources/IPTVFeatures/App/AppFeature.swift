import ComposableArchitecture
import IPTVCore
import IPTVPlayerKit

/// Reducer raíz de la app. Posee la sesión, la feature de Auth, el listado raíz de
/// categorías tras login, y la pila de navegación (`StackState`).
@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        /// `true` mientras se decide (al arrancar) si hay sesión guardada. Muestra
        /// el splash, evitando el parpadeo del login antes de restaurar la sesión.
        public var isLaunching = true
        /// Sesión activa; `nil` mientras no haya login válido.
        public var session: Session?
        /// Autenticación (pantalla inicial cuando no hay sesión).
        public var auth = AuthFeature.State()
        /// Listado de categorías (raíz tras login).
        public var channelList: ChannelListFeature.State?
        /// Pila de navegación.
        public var path = StackState<Path.State>()
        /// Reproductor presentado a pantalla completa (fuera del stack de navegación).
        @Presents public var player: PlayerFeature.State?

        public init() {}

        public struct Session: Equatable {
            public var account: IPTVAccount
            public var status: AccountStatus
        }
    }

    public enum Action {
        case onLaunch
        case restoreFinished(RestoreOutcome)
        case auth(AuthFeature.Action)
        case channelList(ChannelListFeature.Action)
        case path(StackActionOf<Path>)
        case player(PresentationAction<PlayerFeature.Action>)
    }

    /// Resultado de intentar restaurar la sesión al arrancar.
    public enum RestoreOutcome: Equatable {
        case authenticated(IPTVAccount, AccountStatus)
        /// No hay sesión válida; ir al login (con prefill si había credenciales guardadas).
        case needsLogin(prefill: IPTVAccount?)
    }

    /// Destinos navegables (push). El reproductor NO va aquí: se presenta a pantalla
    /// completa para que AVKit gestione controles/rotación de forma nativa.
    @Reducer
    public enum Path {
        case channels(ChannelsFeature)
        case settings(SettingsFeature)
    }

    @Dependency(\.credentialStore) var credentialStore
    @Dependency(\.iptvProvider) var provider
    @Dependency(\.playerEngine) var playerEngine

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Reduce { state, action in
            switch action {
            // MARK: Arranque (restaurar sesión desde Keychain sin parpadeo de login)
            case .onLaunch:
                // Si un hook de demo ya fijó el estado, no restaurar.
                guard state.isLaunching else { return .none }
                return .run { [credentialStore, provider] send in
                    guard let account = try? credentialStore.load() else {
                        await send(.restoreFinished(.needsLogin(prefill: nil)))
                        return
                    }
                    do {
                        let status = try await provider.authenticate(account)
                        await send(.restoreFinished(.authenticated(account, status)))
                    } catch {
                        // Había credenciales pero el re-login falló (red/expirada):
                        // ir al login con los campos rellenos para reintentar.
                        await send(.restoreFinished(.needsLogin(prefill: account)))
                    }
                }

            case let .restoreFinished(outcome):
                state.isLaunching = false
                switch outcome {
                case let .authenticated(account, status):
                    state.session = .init(account: account, status: status)
                    state.channelList = ChannelListFeature.State(account: account)
                case let .needsLogin(prefill):
                    if let account = prefill {
                        state.auth.host = account.host.absoluteString
                        state.auth.username = account.username
                        state.auth.password = account.password
                    }
                }
                return .none

            // MARK: Auth
            case let .auth(.delegate(.authenticated(account, status))):
                state.session = .init(account: account, status: status)
                state.channelList = ChannelListFeature.State(account: account)
                return .none

            case .auth:
                return .none

            // MARK: Listado raíz
            case let .channelList(.delegate(.categorySelected(category, account))):
                state.path.append(.channels(ChannelsFeature.State(account: account, category: category)))
                return .none

            case .channelList(.delegate(.settingsRequested)):
                guard let session = state.session else { return .none }
                state.path.append(.settings(SettingsFeature.State(account: session.account, status: session.status)))
                return .none

            case .channelList:
                return .none

            // MARK: Reproductor (presentación a pantalla completa)
            case let .path(.element(id: _, action: .channels(.delegate(.channelSelected(channel, account))))):
                state.player = PlayerFeature.State(channel: channel, account: account)
                return .none

            // Al cerrarse el reproductor (Done/deslizar/close), parar el motor desde el padre.
            case .player(.dismiss):
                return stopPlayer()

            case .player:
                return .none

            // MARK: Navegación
            case .path(.element(id: _, action: .settings(.delegate(.logoutRequested)))):
                return logout(state: &state)

            case .path:
                return .none
            }
        }
        .ifLet(\.channelList, action: \.channelList) {
            ChannelListFeature()
        }
        .ifLet(\.$player, action: \.player) {
            PlayerFeature()
        }
        .forEach(\.path, action: \.path)
    }

    private func logout(state: inout State) -> Effect<Action> {
        state.session = nil
        state.channelList = nil
        state.auth = AuthFeature.State()
        state.path.removeAll()
        state.player = nil
        return .merge(
            stopPlayer(),
            .run { [credentialStore] _ in try? credentialStore.delete() }
        )
    }

    private func stopPlayer() -> Effect<Action> {
        .run { [playerEngine] _ in playerEngine.stop() }
    }
}

// `StackState<Path.State>` requiere que el estado de las destinations sea Equatable.
extension AppFeature.Path.State: Equatable {}
