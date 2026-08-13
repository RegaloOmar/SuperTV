import ComposableArchitecture
import Foundation
import IPTVCore

/// Autenticación contra un panel Xtream Codes.
///
/// Estados: idle (formulario) → loading → autenticado (delega al padre) o error.
/// Al arrancar restaura la sesión de Keychain e intenta re-login automático.
@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var host: String = ""
        public var username: String = ""
        public var password: String = ""
        public var isLoading: Bool = false
        public var errorMessage: String?

        public init() {}

        /// Normaliza el host: recorta espacios y añade `http://` si falta esquema.
        var normalizedHostURL: URL? {
            let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let candidate = trimmed.contains("://") ? trimmed : "http://\(trimmed)"
            guard let url = URL(string: candidate), url.host() != nil else { return nil }
            return url
        }

        /// Habilita el botón de login solo con campos válidos.
        public var isFormValid: Bool {
            normalizedHostURL != nil
                && !username.trimmingCharacters(in: .whitespaces).isEmpty
                && !password.isEmpty
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case loginButtonTapped
        case authResponse(Result<AccountStatus, IPTVError>, account: IPTVAccount)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            /// Login correcto: el padre (AppFeature) toma el control de la sesión.
            case authenticated(IPTVAccount, AccountStatus)
        }
    }

    @Dependency(\.iptvProvider) var provider
    @Dependency(\.credentialStore) var credentialStore

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                state.errorMessage = nil
                return .none

            case .loginButtonTapped:
                guard let url = state.normalizedHostURL else {
                    state.errorMessage = "La dirección del servidor no es válida."
                    return .none
                }
                let account = IPTVAccount(
                    host: url,
                    username: state.username.trimmingCharacters(in: .whitespaces),
                    password: state.password
                )
                return authenticate(account, state: &state)

            case let .authResponse(.success(status), account):
                state.isLoading = false
                return .run { [credentialStore] send in
                    try? credentialStore.save(account)
                    await send(.delegate(.authenticated(account, status)))
                }

            case let .authResponse(.failure(error), _):
                state.isLoading = false
                state.errorMessage = error.errorDescription
                return .none

            case .delegate:
                return .none
            }
        }
    }

    /// Lanza la autenticación contra el proveedor y mapea el resultado.
    private func authenticate(_ account: IPTVAccount, state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .run { [provider] send in
            do {
                let status = try await provider.authenticate(account)
                await send(.authResponse(.success(status), account: account))
            } catch let error as IPTVError {
                await send(.authResponse(.failure(error), account: account))
            } catch {
                await send(.authResponse(.failure(.network(reason: error.localizedDescription)), account: account))
            }
        }
    }
}
