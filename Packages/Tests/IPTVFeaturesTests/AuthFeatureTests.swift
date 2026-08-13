import Testing
import Foundation
import ComposableArchitecture
import IPTVCore
@testable import IPTVFeatures

/// Proveedor de prueba con un resultado de autenticación fijo.
private struct MockProvider: IPTVProviderProtocol {
    let authResult: Result<AccountStatus, IPTVError>
    func authenticate(_ account: IPTVAccount) async throws -> AccountStatus {
        try authResult.get()
    }
    func liveCategories(for account: IPTVAccount) async throws -> [ChannelCategory] { [] }
    func liveStreams(for account: IPTVAccount, categoryID: String?) async throws -> [Channel] { [] }
}

private let testAccount = IPTVAccount(
    host: URL(string: "http://demo.tv:8080")!,
    username: "user",
    password: "pass"
)

private let activeStatus = AccountStatus(
    state: .active,
    expiresAt: Date(timeIntervalSince1970: 2_000_000_000),
    isTrial: false,
    activeConnections: 1,
    maxConnections: 2
)

@MainActor
@Suite("AuthFeature")
struct AuthFeatureTests {
    private func prefilledState() -> AuthFeature.State {
        var state = AuthFeature.State()
        state.host = "http://demo.tv:8080"
        state.username = "user"
        state.password = "pass"
        return state
    }

    @Test("login correcto persiste la cuenta y delega al padre")
    func loginSuccess() async {
        let cred = InMemoryCredentialStore()
        let store = TestStore(initialState: prefilledState()) {
            AuthFeature()
        } withDependencies: {
            $0.iptvProvider = MockProvider(authResult: .success(activeStatus))
            $0.credentialStore = cred
        }

        await store.send(.loginButtonTapped) { $0.isLoading = true }
        await store.receive(\.authResponse) { $0.isLoading = false }
        await store.receive(\.delegate)  // .authenticated(account, status)

        // La cuenta quedó persistida en el store (Keychain en producción).
        #expect((try? cred.load()) == testAccount)
    }

    @Test("credenciales inválidas muestran error y no persisten")
    func loginInvalidCredentials() async {
        let cred = InMemoryCredentialStore()
        let store = TestStore(initialState: prefilledState()) {
            AuthFeature()
        } withDependencies: {
            $0.iptvProvider = MockProvider(authResult: .failure(.invalidCredentials))
            $0.credentialStore = cred
        }

        await store.send(.loginButtonTapped) { $0.isLoading = true }
        await store.receive(\.authResponse) {
            $0.isLoading = false
            $0.errorMessage = IPTVError.invalidCredentials.errorDescription
        }

        #expect((try? cred.load()) == nil)
    }
}
