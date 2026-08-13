import ComposableArchitecture
import IPTVCore

/// Reducer raíz de la app. Posee la sesión, la feature de Auth, el listado raíz de
/// categorías tras login, y la pila de navegación (`StackState`).
@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        /// Sesión activa; `nil` mientras no haya login válido.
        public var session: Session?
        /// Autenticación (pantalla inicial cuando no hay sesión).
        public var auth = AuthFeature.State()
        /// Listado de categorías (raíz tras login).
        public var channelList: ChannelListFeature.State?
        /// Pila de navegación.
        public var path = StackState<Path.State>()

        public init() {}

        public struct Session: Equatable {
            public var account: IPTVAccount
            public var status: AccountStatus
        }
    }

    public enum Action {
        case auth(AuthFeature.Action)
        case channelList(ChannelListFeature.Action)
        case path(StackActionOf<Path>)
    }

    /// Destinos navegables.
    @Reducer
    public enum Path {
        case channels(ChannelsFeature)
        case player(PlayerFeature)
        case settings(SettingsFeature)
    }

    @Dependency(\.credentialStore) var credentialStore

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Reduce { state, action in
            switch action {
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

            // MARK: Navegación
            case let .path(.element(id: _, action: .channels(.delegate(.channelSelected(channel, account))))):
                state.path.append(.player(PlayerFeature.State(channel: channel, account: account)))
                return .none

            case let .path(.element(id: id, action: .player(.delegate(.dismiss)))):
                state.path.pop(from: id)
                return .none

            case .path(.element(id: _, action: .settings(.delegate(.logoutRequested)))):
                return logout(state: &state)

            case .path:
                return .none
            }
        }
        .ifLet(\.channelList, action: \.channelList) {
            ChannelListFeature()
        }
        .forEach(\.path, action: \.path)
    }

    private func logout(state: inout State) -> Effect<Action> {
        state.session = nil
        state.channelList = nil
        state.auth = AuthFeature.State()
        state.path.removeAll()
        return .run { [credentialStore] _ in try? credentialStore.delete() }
    }
}

// `StackState<Path.State>` requiere que el estado de las destinations sea Equatable.
extension AppFeature.Path.State: Equatable {}
