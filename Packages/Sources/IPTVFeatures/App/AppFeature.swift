import ComposableArchitecture
import IPTVCore
import IPTVPlayerKit

/// Reducer raíz de la app. Posee la sesión, la feature de Auth, y la navegación
/// master-detail (categorías ↔ canales) que se adapta a iPhone (stack) e iPad (split).
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
        /// Listado de categorías (sidebar en iPad / raíz en iPhone).
        public var channelList: ChannelListFeature.State?
        /// Canales de la categoría seleccionada (detalle en iPad / push en iPhone).
        @Presents public var channels: ChannelsFeature.State?
        /// Ajustes, presentados como hoja.
        @Presents public var settings: SettingsFeature.State?
        /// Reproductor a pantalla completa (AVKit gestiona controles/rotación nativos).
        @Presents public var player: PlayerFeature.State?

        public init() {}

        public struct Session: Equatable {
            public var account: IPTVAccount
            public var status: AccountStatus

            public init(account: IPTVAccount, status: AccountStatus) {
                self.account = account
                self.status = status
            }
        }
    }

    public enum Action {
        case onLaunch
        case restoreFinished(RestoreOutcome)
        case auth(AuthFeature.Action)
        case channelList(ChannelListFeature.Action)
        case channels(PresentationAction<ChannelsFeature.Action>)
        case settings(PresentationAction<SettingsFeature.Action>)
        case player(PresentationAction<PlayerFeature.Action>)
    }

    /// Resultado de intentar restaurar la sesión al arrancar.
    public enum RestoreOutcome: Equatable {
        case authenticated(IPTVAccount, AccountStatus)
        /// No hay sesión válida; ir al login (con prefill si había credenciales guardadas).
        case needsLogin(prefill: IPTVAccount?)
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

            // MARK: Categorías (sidebar) → seleccionar categoría abre sus canales (detalle)
            case let .channelList(.delegate(.categorySelected(category, account))):
                // Si ya se está mostrando esa categoría, no recrear el estado: en iPad
                // el detalle está fijado con `.id(category.id)` y el `.task(id:)` no se
                // vuelve a disparar, así que un estado nuevo quedaría vacío sin recargar.
                guard state.channels?.category.id != category.id else { return .none }
                state.channels = ChannelsFeature.State(account: account, category: category)
                return .none

            case .channelList(.delegate(.settingsRequested)):
                guard let session = state.session else { return .none }
                state.settings = SettingsFeature.State(account: session.account, status: session.status)
                return .none

            case .channelList:
                return .none

            // MARK: Canales (detalle) → seleccionar canal presenta el reproductor
            case let .channels(.presented(.delegate(.channelSelected(channel, account)))):
                state.player = PlayerFeature.State(channel: channel, account: account)
                return .none

            case .channels:
                return .none

            // MARK: Settings (hoja)
            case .settings(.presented(.delegate(.logoutRequested))):
                return logout(state: &state)

            case .settings:
                return .none

            // MARK: Reproductor (cover)
            case .player(.dismiss):
                return stopPlayer()

            case .player:
                return .none
            }
        }
        .ifLet(\.channelList, action: \.channelList) {
            ChannelListFeature()
        }
        .ifLet(\.$channels, action: \.channels) {
            ChannelsFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
        .ifLet(\.$player, action: \.player) {
            PlayerFeature()
        }
    }

    private func logout(state: inout State) -> Effect<Action> {
        state.session = nil
        state.channelList = nil
        state.channels = nil
        state.settings = nil
        state.player = nil
        state.auth = AuthFeature.State()
        return .merge(
            stopPlayer(),
            .run { [credentialStore] _ in try? credentialStore.delete() }
        )
    }

    private func stopPlayer() -> Effect<Action> {
        .run { [playerEngine] _ in playerEngine.stop() }
    }
}
